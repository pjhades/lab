# 新手任务：简单CDN节点搭建攻略


架构
=============
### 概览
现有6台主机可用：`v132{083,168,169,170,171,172}.sqa.cm4`.
括号中的数字表示其IP的低8位，IP前缀均为10.232.132，以下省略。

节点结构如下：

                           request
                              |
                              V
                          
          ------------ Virtual IP .244:80 ------------
    
    LVS master (.83)  --- keepalived --- LVS backup (.168)
             |        \__             __/   |
             |           \___________/      |
    haproxy (.169:80) ___/           \___ haproxy (.170:80)
             |           \___________/      |
             |           /           \      |
    swift (.171:9090) __/             \__ swift (.172:9090)
              \                            /
               \                          /
                          source site


### 访问流程
来自客户端的请求发往VIP 10.232.132.244:80，
LVS服务器按VS/DR模式将其转发给后端的真实服务器，
其上运行haproxy进行应用层的负载均衡和第一级缓存。
Haproxy根据hash算法将请求转发给后端的swift，
由swift决定响应如何处理（从源站取数据、从对等节点取数据，etc.）。
最终的响应由haproxy返回给客户端（假设LVS工作在VS/DR模式）。



日志
=============
### keepalived
使用keepalived启动命令行参数（详见`man keepalived`）：

    --log-console, -l
           Log messages to local console.
    
    --log-detail, -D
           Detailed log messages (the default with the rc script provided).
    
    --log-facility, -S
           0-7 Set syslog facility to LOG_LOCAL[0-7] (default=LOG_DAEMON)

例如我们指定`-D -S2`，并将以下一行加入`/etc/syslog.conf`，设置日志文件位置：

    local2.*    /path/to/keepalived.log

然后重启syslog。


### swift
在swift的配置文件中可设置日志文件和coredump目录，例如：

    access_log /home/yourname/swift_test/access.log
    cache_log /home/yourname/swift_test/cache.log
    coredump_dir /home/yourname/swift_test/


### haproxy
在haproxy的配置文件的段中加入：

    log 127.0.0.1 local2

Haproxy和syslogd经UDP通信，所以需要以`-r`参数启动syslogd，并保证
`/etc/services`文件中有如下一行（详见`man syslogd`）：

    syslog        514/udp

P.S. 为啥我至今还没看到过这日志……



配置
=============
#### Swift
##### 方法
先从后端开始配置。（swift有个配置手册就好了）

    # 磁盘I/O和网络线程数
    io_thread_cnt 4
    file_thread_cnt 4
    
    # 创建ACL all：一切源地址
    acl all src all
    # 允许列表all中的所有地址访问
    http_access allow all
    
    # 创建ACL service_domain：指定目的站点域名
    acl service_domain dstdomain alibaba.com taobao.com
    
    # 监听来自9090端口的请求
    http_port 9090
    
    # 配置源站作为父节点，端口8765，使用HTTP/1.1，在所有
    # 父节点之间按round robin递交请求
    cache_peer 10.232.129.35 parent 8765 0 http11 round-robin weight=1 priority=2
    # 允许列表service_domain访问父节点
    cache_peer_access 10.232.129.35 allow service_domain
    
    # 内存cache
    cache_mem 256 MB
    only_use_cache_mem on
    
    # 磁盘缓存文件
    cache_dir coss /home/pengjing.pj/swift_test/ 1000 block-size=512 max-size=1M maxfullbufs=120 migration-weight=4 migration-power=0.8
    
    # swift进程的EUID和EGID
    cache_effective_user pengjing.pj
    cache_effective_group users
    
    # 日志和coredump
    access_log /home/pengjing.pj/swift_test/access.log
    cache_log /home/pengjing.pj/swift_test/cache.log
    coredump_dir /home/pengjing.pj/swift_test/
    
    # PID文件和磁盘对象索引文件
    pid_filename /home/pengjing.pj/swift_test/swift.pid
    sht_filename /home/pengjing.pj/swift_test/swift.sht

##### 坑
之前删掉了`cache_peer`和`cache_peer_access`两行，结果所有以该swift为代理的访问
都返回503。求助空见师兄后得到的解释：

> swift支持2种方式回源
> 1.cache_peer,就是我们配置的那种
> 2.srv dns，这个是指swift会到指定的dns服务器查询域名的_http._tcp服务的位置
> 比如：
>
>      11 dns_resolv_file /home/kongjian/swift_test/resolv.conf
>      12 dns_resolv_domain inner.taobao.com
>      13 dns_use_resolv on
>
> 其中resolv.conf的内容是，10.232.132.170 上面已经配置好了dns服务器，里面有一些域名的srv记录，比如img01.taobaocdn.com
> 
>     [kongjian@v132172.sqa.cm4 swift_test]$ cat /home/kongjian/swift_test/resolv.conf 
>     nameserver 10.232.132.170
> 
> 测试：
> 
>     [kongjian@v132172.sqa.cm4 swift_test]$ nslookup -q=srv  _http._tcp.img01.taobaocdn.com.inner.taobao.com 10.232.132.170
>     Server:         10.232.132.170
>     Address:        10.232.132.170#53
>     _http._tcp.img01.taobaocdn.com.inner.taobao.com service = 1 1 80 125.39.85.250.
> 
> 默认不配置的话都是503


#### Haproxy
##### 方法
由于LVS后端的真实服务器与负载均衡器在同一网络上共享VIP地址，
所以需要在两台haproxy服务器上配置之。通常将VIP地址配置在虚接口lo:0上作为lo的别名，
不影响eth0接口（VIP放在eth0上也行，但是我一时没想到什么情况下会影响eth0的正常通信）。

    # ifconfig lo:0 10.232.132.244 netmask 255.255.255.255 broadcast 255.255.255.255

因为要保证将客户端请求交给负载均衡器，所以需要关闭真实服务器对ARP请求的响应。
修改`/etc/sysctl.conf`设置内核参数：

    net.ipv4.conf.lo.arp_ignore = 1
    net.ipv4.conf.lo.arp_announce = 2
    net.ipv4.conf.all.arp_ignore = 1
    net.ipv4.conf.all.arp_announce = 2

执行`sysctl -p`使设置生效。

以上配置中，`arp_announce`选项设置从某个接口发出去的ARP请求中声明本地IP地址的方式。
从[Linux内核文档](http://serverfault.com/questions/500440/should-icmp-redirects-be-turned-on-servers-running-lvskeepalived)可知，
设置的等级越高，ARP请求发送方的有效IP越不容易被发送。
`arp_ignore`选项设置针对本地IP地址的ARP请求的应答方式。等级1表示
“reply only if the target IP address is local address configured on the incoming interface”
（中文太绕了）。

然后是haproxy的配置文件：

    global
        # Process management and security
        log 127.0.0.1 local2
        # daemon运行时的进程数
        nbproc  1
        # PID文件
        pidfile /var/run/haproxy.pid
    
        maxconn 65536
        # 不使用poll
        nopoll
        # 不使用epoll
        nosepoll
        # 关闭TCP slicing
        nosplice
        # 把健康检查搞随机点
        spread-checks 3 50%
        # cache对象的对大大小(非官方)
        max-obj-size 512K
        # 过期时间
        cache-expire 500m
        # 统计间隔时间
        stats-interval 1
        cache-chunk-size 4K
    
    defaults
        # 运行HTTP协议
        mode http
        # 在转发给服务器的请求中使用X-Forwarded-For header
        option forwardfor
        # 不将没有数据传输的连接记入日志
        option dontlognull
        # 等请求传输完全结束后再记录日志
        no option logasap
        # 设置用于统计的URI前缀, 以该前缀开始的URI将被
        # 当作统计请求
        stats uri /admin?stats
        # 客户端连接超时时长(客户端需发数据, 确认等)
        timeout client 10000
        # 连接到服务器的超时时长
        timeout connect 5000
        # 服务器空闲超时时长(服务器需发数据, 确认等)
        timeout server 5000
    
    frontend web_proxy
        # 监听本机80端口
        bind 0.0.0.0:80
        # 当没有use_backend规则时选择的默认后端
        default_backend edge_cache_servers
    
        # 日志
        option httplog squidlog
        log 127.0.0.1 local2
    
        # 在服务器端使用Connection: close, haproxy
        # 转发给服务器的请求中设置该header
        option http-server-close
        # 防止服务器端因Connection: close而不用chunked encoding
        option http-pretend-keepalive
        # (非官方)在服务端使用HTTP keepalive
        option http-server-keepalive

        # 每个进程的最大并发连接数
        maxconn 65536
    
    backend edge_cache_servers
        # 服务器端开启TCP keepalive心跳
        option srvtcpka

        option httplog squidlog
        log 127.0.0.1 local2

        # 对后端按请求URI hash进行负载均衡
        balance uri

        # 后端服务器的地址
        server swift171 10.232.132.171:9090 id 1002
        server swift172 10.232.132.172:9090 id 1003
    
    global
        ecc-console-addr 10.232.132.170:8080


##### 坑
如前所述，LVS后端的真实服务器需要关闭ARP响应。否则，若真实服务器响应
对VIP地址的ARP请求，则本应发往VIP的报文可能被发往LVS服务器或某一真实服务器，
LVS集群的正常工作即被破坏。这一问题（[ARP problem ](http://serverfault.com/questions/500440/should-icmp-redirects-be-turned-on-servers-running-lvskeepalived)）
在VS/TUN和VS/DR两种工作模式下
均会出现，因为这两种模式下VIP地址都会由LVS服务器和真实服务器共享。



#### LVS与keepalived
##### 方法
Keepalived实现了VRRP来进行master节点的选举和故障切换（failover），
与LVS协同工作，便于配置。
首先修改内核参数：

    net.ipv4.ip_forward = 0
    net.ipv4.conf.all.send_redirects = 0
    net.ipv4.conf.default.send_redirects = 0
    net.ipv4.conf.eth0.send_redirects = 0

Master节点上keepalived和LVS的配置如下。Backup节点上需要修改初始状态
和节点的优先级。

    global_defs {
        router_id LVS_DEVEL
    }
    
    # 当前主机上运行的VRRP实例
    vrrp_instance toy_cdn_vi {
        # 初始状态指定为master
        state MASTER
        # VRRP运行的接口
        interface eth0
        # 虚拟路由器ID, 作为虚拟MAC地址最低段
        virtual_router_id 11
        # 当前主机的优先级
        priority 100
        # VRRP周期通告发送间隔
        advert_int 1
    
        # VRRP报文验证方式
        authentication {
            auth_type PASS
            auth_pass 1234
        }
    
        # 要使用的虚拟IP地址
        virtual_ipaddress {
            10.232.132.244/24
        }
    }
    
    # 定义虚拟服务组, 一个真实服务器上的服务可以属于多个组
    virtual_server_group toy_cdn {
        10.232.132.244 80
    }
    
    # 或者写成
    #   virtual_server group toy_cdn {
    # 定义虚拟服务器
    virtual_server 10.232.132.244 80 {
        # 检查间隔时间
        delay_loop 5
        # 设置LVS负载均衡算法
        lb_algo wrr 
        # 设置LVS集群工作模式
        lb_kind DR
        # 设置连接保持时间, 主要用于会话保持
        persistence_timeout 50
        # 使用TCP协议
        protocol TCP 
    
        # 后端真实服务器
        real_server 10.232.132.169 80 {
            # 用于负载均衡的权值
            weight 1
            # 使用TCP进行健康检查
            TCP_CHECK {
                connect_port 80
                connect_timeout 10
                # 重试次数
                nb_get_retry 3
                # 重试之前的间隔
                delay_before_retry 3
            }   
        }   
    
        real_server 10.232.132.170 80 {
            weight 1
            TCP_CHECK {
                connect_port 80
                connect_timeout 10
                nb_get_retry 3
                delay_before_retry 3
            }
        }
    }

启动keepalived服务后，安装LVS的管理工具ipvsdam，用其查看虚实服务器的映射是否配置成功：

    # ipvsadm -ln
    IP Virtual Server version 1.2.1 (size=4096)
    Prot LocalAddress:Port Scheduler Flags
      -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
    TCP  10.232.132.244:80 wrr persistent 50
      -> 10.232.132.170:80            Route   1      0          0         
      -> 10.232.132.169:80            Route   1      0          0     

可通过查看keepalived日志和eth0端口的IP地址来确定当前的master节点。
停掉master节点上的keepalived，一段时间（根据配置而定）后可观察到VIP地址切换到了backup节点。



参考
=============
1. http://www.austintek.com/LVS/LVS-HOWTO/HOWTO/LVS-HOWTO.arp_problem.html
1. http://cbonte.github.io/haproxy-dconv/configuration-1.5.html
1. Internetworking with TCP/IP: Principles, Protocols and Architectures, 5ed
1. RFC 5798



致谢
=============
空见、元朔
