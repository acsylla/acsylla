cdef class PreparedStatement:
    cdef:
        const CassPrepared* cass_prepared
        object timeout
        object consistency
        const CassKeyspaceMeta* keyspace_meta

    @staticmethod
    cdef PreparedStatement new_(const CassPrepared* cass_prepared, object timeout, object consistency, const CassKeyspaceMeta* keyspace_meta)
