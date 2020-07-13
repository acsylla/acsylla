cdef class Statement:
    cdef:
        int parameters
        CassStatement* cass_statement

    cdef _check_index_or_raise(self, index)
    cdef _check_bind_error_or_raise(self, CassError error)
