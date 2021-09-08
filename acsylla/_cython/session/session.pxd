cdef class Session:
    cdef:
        CassCluster* cass_cluster
        CassSession* cass_session
        object loop
        object keyspace
        bint closed
        bint connected
        const CassSchemaMeta* schema_meta
        const CassKeyspaceMeta* keyspace_meta
