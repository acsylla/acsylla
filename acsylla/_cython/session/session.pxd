cdef class Session:
    cdef:
        CassCluster* cass_cluster
        CassSession* cass_session
        object loop
        object keyspace
        bint closed
        bint connected

    cdef _raise_if_error(self, CassFuture * cass_future)
