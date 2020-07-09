cdef class Value:
    cdef:
        const CassValue* cass_value

    @staticmethod
    cdef Value new_(CassValue* cass_value)
