cdef class Result:
    cdef:
        const CassResult* cass_result
        public object tracing_id
        public int8_t native_types

    @staticmethod
    cdef Result new_(const CassResult* cass_result, int8_t native_types)

    
