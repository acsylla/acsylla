cdef class PreparedStatement:
    cdef:
        Session session
        const CassPrepared* cass_prepared
        object timeout
        object consistency
        object serial_consistency
        object execution_profile
        object native_types

    @staticmethod
    cdef PreparedStatement new_(Session session,
                                const CassPrepared* cass_prepared,
                                object timeout,
                                object consistency,
                                object serial_consistency,
                                object execution_profile,
                                object native_types)
