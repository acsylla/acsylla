cdef class Batch:
    cdef:
        CassBatch* cass_batch
        public object tracing_enabled

    @staticmethod
    cdef Batch new_(CassBatchType type_, object timeout, str execution_profile)
