cdef class PreparedStatement:
    cdef:
        const CassPrepared* cass_prepared

    @staticmethod
    cdef PreparedStatement new_(const CassPrepared* cass_prepared)
