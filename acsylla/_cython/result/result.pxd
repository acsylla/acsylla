cdef class Result:
    cdef:
        const CassResult* cass_result

    @staticmethod
    cdef Result new_(const CassResult* cass_result)

    
