cdef class Cluster:
    cdef:
        CassCluster* cass_cluster
