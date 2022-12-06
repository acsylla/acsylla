cdef class PreparedStatement:
    cdef:
        const CassPrepared* cass_prepared
        object timeout
        object consistency
        object serial_consistency
        object execution_profile

    @staticmethod
    cdef PreparedStatement new_(const CassPrepared* cass_prepared,
                                object timeout,
                                object consistency,
                                object serial_consistency,
                                object execution_profile)
