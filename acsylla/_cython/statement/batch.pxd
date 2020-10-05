cdef class Batch:
    cdef:
        CassBatch* cass_batch

    @staticmethod
    cdef Batch new_(CassBatchType type_, object timeout)
