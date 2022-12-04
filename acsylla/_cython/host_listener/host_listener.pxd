ctypedef struct HostListenerMessage:
    CassHostListenerEvent event
    CassInet inet

ctypedef queue[HostListenerMessage] _host_listener_queue

cdef class HostListener:
    cdef:
        mutex _mutex
        int _write_fd
        object _read_socket
        object _write_socket
        _host_listener_queue _queue
        object host_listener_callback

    @staticmethod
    cdef void _callback(CassHostListenerEvent event, CassInet inet, void* data)
    cdef init(self, CassCluster* cass_cluster, object callback)
    cdef void _write(self, int fd) nogil