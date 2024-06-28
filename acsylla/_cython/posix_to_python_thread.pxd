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

ctypedef struct LogMessageCallback:
    CassLogMessage msg
    void* logger

ctypedef queue[void *] cpp_event_queue
ctypedef queue[LogMessageCallback] cpp_log_queue

cdef int _socket_write(int fd) noexcept nogil
cdef int _socket_close(int fd) noexcept nogil

cdef void cb_cass_future(CassFuture* cass_future, void* data)
cdef void cb_log_message(const CassLogMessage* message, void* data)


cdef cpp_event_queue _queue
cdef cpp_log_queue _log_queue
cdef mutex _queue_mutex
cdef mutex _log_queue_mutex
cdef int _write_fd
cdef int _log_write_fd
cdef object _read_socket
cdef object _log_read_socket
cdef object _write_socket
cdef object _log_write_socket
cdef object _loop
cdef object _thread_id
