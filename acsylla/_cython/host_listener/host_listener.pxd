ctypedef struct HostListenerMessage:
    CassHostListenerEvent event
    CassInet address


cdef class HostListener:
    cdef:
        mutex _mutex
        int _write_fd
        object _read_socket
        object _write_socket
        object host_listener_callback
        queue[HostListenerMessage] _queue

    @staticmethod
    cdef void _callback(CassHostListenerEvent event, const CassInet address, void* data)
    cdef init(self, CassCluster* cass_cluster, object callback)