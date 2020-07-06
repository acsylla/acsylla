cdef extern from "<queue>" namespace "std" nogil:
    cdef cppclass queue[T]:
        queue()
        bint empty()
        T& front()
        void pop()
        void push(T&)
        size_t size()


cdef extern from "<mutex>" namespace "std" nogil:
    cdef cppclass mutex:
        mutex()
        void lock()
        void unlock()


ctypedef queue[void *] cpp_event_queue


cdef void _socket_write(int fd) nogil
cdef void _socket_close(int fd) nogil

cdef void cb_cass_future(CassFuture* cass_future, void* data)


cdef cpp_event_queue _queue
cdef mutex _queue_mutex
cdef int _write_fd
cdef object _read_socket
cdef object _write_socket
cdef object _loop
cdef object _thread_id
