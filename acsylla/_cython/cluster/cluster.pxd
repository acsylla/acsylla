cdef class Cluster:
    cdef:
        PosixToPython* posix_to_python
        CassCluster* cass_cluster
        CassSsl* ssl
        Logger logger
        HostListener host_listener
        object _read_socket
        object _write_socket
        object loop
