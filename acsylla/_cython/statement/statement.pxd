cdef class Statement:
    cdef:
        bint prepared
        CassStatement* cass_statement

    @staticmethod
    cdef Statement new_from_string(str statement_str, int parameters)

    @staticmethod
    cdef Statement new_from_prepared(CassStatement* cass_statement)

    cdef _check_bind_error_or_raise(self, CassError error)
