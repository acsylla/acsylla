cdef class Session:
    cdef:
        CassCluster* cass_cluster
        CassSession* cass_session
        object loop
        object keyspace
        bint closed
        bint connected
        const CassSchemaMeta* _schema_meta
        const CassSchemaMeta* schema_meta(self)