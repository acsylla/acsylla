cdef class Cluster:
    cdef:
        CassCluster* cass_cluster
        CassSsl* ssl
        Logger logger
