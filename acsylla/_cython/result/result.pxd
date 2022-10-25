cdef class Result:
    cdef:
        const CassResult* cass_result
        public object tracing_id

    @staticmethod
    cdef Result new_(const CassResult* cass_result)

    
