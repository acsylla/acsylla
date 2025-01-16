cdef class HostListener:
    cdef:
        object _read_socket
        object _write_socket
        object host_listener_callback
        PosixToPythonHostListener* posix_to_python

    cdef init(self, CassCluster* cass_cluster, object callback)