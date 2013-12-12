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

分配
去掉了`MEMPROTECT`、`SANITY`、死牛肉等一大堆宏之后，64bit系统上实现是这样的。

    c:
    void *
    ink_freelist_new(InkFreeList * f)
    {
      head_p item;
      head_p next;
      int result = 0;
    
      do {
        // 取head结点到item
        INK_QUEUE_LD(item, f->head);
         
        // 取head结点中保存的指针，判空
        if (TO_PTR(FREELIST_POINTER(item)) == NULL) {
          // 空指针，没货了，要分配新的
          uint32_t type_size = f->type_size;
          uint32_t i;
           
          // newp：新申请的内存，一次申请了chunk_size个type_size
          void *newp = NULL;
          if (f->alignment)
            newp = ats_memalign(f->alignment, f->chunk_size * type_size);
          else
            newp = ats_malloc(f->chunk_size * type_size);
          fl_memadd(f->chunk_size * type_size);
           
          // 初始化item：指针为新申请的newp，版本号为0
          SET_FREELIST_POINTER_VERSION(item, newp, 0);
           
          ink_atomic_increment((int *) &f->allocated, f->chunk_size);
          ink_atomic_increment(&fastalloc_mem_total, (int64_t) f->chunk_size * f->type_size);
    
          /* free each of the new elements */
          // 把新申请的每个chunk挂到free list上
          for (i = 0; i < f->chunk_size; i++) {
            char *a = ((char *) FREELIST_POINTER(item)) + i * type_size;
            ink_freelist_free(f, a);
          }
           
          ink_atomic_increment((int *) &f->used, f->chunk_size);
          ink_atomic_increment(&fastalloc_mem_in_use, (int64_t) f->chunk_size * f->type_size);
    
        } else {
          // 有可用的chunk
          // 初始化next结点，即要用于更新的新的head。指针为刚取出的item中的指针，版本号为原来的版本号+1
          SET_FREELIST_POINTER_VERSION(next, *ADDRESS_OF_NEXT(TO_PTR(FREELIST_POINTER(item)), 0),
                                       FREELIST_VERSION(item) + 1);
          // 更新head结点
          result = ink_atomic_cas((int64_t *) & f->head.data, item.data, next.data);
        }
      }
      while (result == 0);
       
      ink_assert(!((uintptr_t)TO_PTR(FREELIST_POINTER(item))&(((uintptr_t)f->alignment)-1)));
    
      ink_atomic_increment((int *) &f->used, 1);
      ink_atomic_increment(&fastalloc_mem_in_use, (int64_t) f->type_size);
    
      return TO_PTR(FREELIST_POINTER(item));
    }


释放

    c:
    typedef volatile void *volatile_void_p;
     
    void
    ink_freelist_free(InkFreeList * f, void *item)
    {
      // 记录item指向的对象的起始地址
      volatile_void_p *adr_of_next = (volatile_void_p *) ADDRESS_OF_NEXT(item, 0);
      head_p h;
      head_p item_pair;
      int result;
    
      result = 0;
      do {
        INK_QUEUE_LD(h, f->head);
         
        // 把item加到free list最前面
        *adr_of_next = FREELIST_POINTER(h);
         
        // 为这个item初始化一个item_pair，指针为item，版本号为原来head结点的版本号
        SET_FREELIST_POINTER_VERSION(item_pair, FROM_PTR(item), FREELIST_VERSION(h));
        INK_MEMORY_BARRIER;
        // 更新head结点
        result = ink_atomic_cas((int64_t *) & f->head, h.data, item_pair.data);
      }
      while (result == 0);
    
      ink_atomic_increment((int *) &f->used, -1);
      ink_atomic_increment(&fastalloc_mem_in_use, -(int64_t) f->type_size);
    }






atomic list

    c:
      typedef struct
      {
        volatile head_p head;
        const char *name;
        uint32_t offset;
      } InkAtomicList;

类似于free list，用这个头结点来引用就好了。

    l --> +--------+
          | head   |             
          +--------+
          | name   |
          +--------+
          | offset |
          +--------+
    
                head.data
        +----------------+----------------+
        | 16-bit version | 48-bit pointer |
        +----------------+-------|--------+
                                 |
               +-----------------+
               |
               V
            ---+-------+-------+-------+----------
               |val|ptr|       |val|ptr| 
            ---+-----|-+-------^-----|-+-----^----
               |<->| |         |<->| |       |
                 |    \-------/  |    \-----/
                 |               |
               offset          offset


`ink_atomiclist_init`，初始化，设置`head`中的指针和版本号均为0

push

    c:
    void *
    ink_atomiclist_push(InkAtomicList * l, void *item)
    {
      volatile_void_p *adr_of_next = (volatile_void_p *) ADDRESS_OF_NEXT(item, l->offset);
      head_p head;
      head_p item_pair;
      int result = 0;
      volatile void *h = NULL;
      do {
        INK_QUEUE_LD(head, l->head);
        h = FREELIST_POINTER(head);
        *adr_of_next = h;
        ink_assert(item != TO_PTR(h));
        // 新的head结点：指针为item，版本号为原来head中记录的版本号
        SET_FREELIST_POINTER_VERSION(item_pair, FROM_PTR(item), FREELIST_VERSION(head));
        INK_MEMORY_BARRIER;
    #if TS_HAS_128BIT_CAS
           result = ink_atomic_cas((__int128_t*) & l->head, head.data, item_pair.data);
    #else
           result = ink_atomic_cas((int64_t *) & l->head, head.data, item_pair.data);
    #endif
      }
      while (result == 0);
    
      return TO_PTR(h);
    }



pop

    c:
    void *
    ink_atomiclist_pop(InkAtomicList * l)
    {
      head_p item;
      head_p next;
      int result = 0;
      do {
        INK_QUEUE_LD(item, l->head);
        if (TO_PTR(FREELIST_POINTER(item)) == NULL)
          return NULL;
        // pop之后的新的head结点，版本号+1
        SET_FREELIST_POINTER_VERSION(next, *ADDRESS_OF_NEXT(TO_PTR(FREELIST_POINTER(item)), l->offset),
                                     FREELIST_VERSION(item) + 1);
    #if TS_HAS_128BIT_CAS
           result = ink_atomic_cas((__int128_t*) & l->head.data, item.data, next.data);
    #else
           result = ink_atomic_cas((int64_t *) & l->head.data, item.data, next.data);
    #endif
      }
      while (result == 0);

      {
        void *ret = TO_PTR(FREELIST_POINTER(item));
        *ADDRESS_OF_NEXT(ret, l->offset) = NULL;
        return ret;
      }
    }
