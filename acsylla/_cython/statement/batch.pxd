cdef class Batch:
    cdef:
        CassBatch* cass_batch
        public object tracing_enabled
        # Statements with decimals bound as the text of acsylla 1.x and as CQL defines them
        bint legacy_decimals
        bint cql_decimals

    @staticmethod
    cdef Batch new_(CassBatchType type_, object timeout, str execution_profile)
