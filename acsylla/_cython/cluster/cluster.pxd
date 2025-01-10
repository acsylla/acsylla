cdef class Cluster:
    cdef:
        CassCluster* cass_cluster
        CassSsl* ssl
        Logger logger
        HostListener host_listener
        queue[void *] _queue
        mutex _queue_mutex
        int _write_fd
        object _read_socket
        object _write_socket
        object loop

    @staticmethod
    cdef void cb_cass_future(CassFuture* cass_future, void* data)
    cdef int _socket_write(self, int fd) noexcept nogil
