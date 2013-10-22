free list的head类型，x86\_64上只有一个64bit的data成员。

    c:
      typedef union
      {
    #if (defined(__i386__) || defined(__arm__)) && (SIZEOF_VOIDP == 4)
        struct
        {
          void *pointer;
          int32_t version;
        } s;
        int64_t data;
    #elif TS_HAS_128BIT_CAS
        struct
        {
          void *pointer;
          int64_t version;
        } s;
        __int128_t data;
    #else
        int64_t data;
    #endif
      } head_p;


free list

每个free list上管理了一定大小的、动态分配的可用的内存，由一个头结点（`InkFreeList`）开始。
所有free list通过类型为`ink_freelist_list`的结点串成一个链表，指针为全局的`freelists`。

    c:
      struct _InkFreeList
      {
        volatile head_p head;
        const char *name;
        uint32_t type_size, chunk_size, used, allocated, alignment;
        uint32_t allocated_base, used_base;
      };
       
      typedef struct _InkFreeList InkFreeList, *PInkFreeList;

      typedef struct _ink_freelist_list
      {
        InkFreeList *fl;
        struct _ink_freelist_list *next;
      } ink_freelist_list;

      extern ink_freelist_list *freelists;


结构如下
                 ink_freelist_list
                   +------+             +------+
    freelists ---->|  fl -----+         |  fl  |
                   +------+   |         +------+
                   | next-----|-------->| next--------> ...
                   +------+   |         +------+
                              |
                              |
                 InkFreeList  |
                   +------+<--+
                   | head |
                   |      |
                   |  ..  |
                   +------+
    
                head.data
        +----------------+----------------+
        | 16-bit version | 48-bit pointer |
        +----------------+-------|--------+
                                 |
               +-----------------+
               |
               V
          ---+----+-------+----+-----+----+---
             ||||||       ||||||     ||||||
          ---+--|-+-------+-^|-+-----+-^--+---
                |           ||         |
                 \---------/  \-------/

每个free list的头结点中保存了一次分配的大小（`type_size`）、一次分配的块数（`chunk_size`），
以及一些统计信息。创建一个新的free list后（`ink_freelist_create`），这个新的freelist会加入到全局的链表中。
分配、释放等操作只需要提供free list的头结点即可。

分配和释放
注意每个free list上的可用空间中保存的都是下一块的指针。
* `ink_freelist_new`，从目标free list中取出第一块可用内存，取不到就分配，版本号初始化为0
* `ink_freelist_free`，将目标指针指向的空间归还到free list中，版本号加1


atomic list


    c:
      typedef struct
      {
        volatile head_p head;
        const char *name;
        uint32_t offset;
      } InkAtomicList;

类似于free list，用这个头结点来引用就好了。

`ink_atomiclist_init`，初始化，设置`head`中的指针和版本号均为0
`ink_atomiclist_push()`，新

