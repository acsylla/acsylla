cdef class Session:
    cdef:
        Cluster cluster
        CassCluster* cass_cluster
        CassSession* cass_session
        object loop
        bint closed
        bint connected
        public object keyspace
