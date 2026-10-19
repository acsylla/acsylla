from libcpp.vector cimport vector


cdef class Result:
    cdef:
        const CassResult* cass_result
        public object tracing_id
        public int8_t native_types
        # NATIVE_TYPES and LEGACY_TYPES, the values of the rows are made by them
        int8_t flags
        vector[CassIterator*] iterator_refs
        list _columns_names_cache

    @staticmethod
    cdef Result new_(const CassResult* cass_result, int8_t native_types, bint legacy_types)

    
