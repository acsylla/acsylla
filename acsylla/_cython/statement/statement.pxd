cdef class Statement:
    cdef:
        bint prepared
        CassStatement* cass_statement

    @staticmethod
    cdef Statement new_from_string(str statement_str, int parameters, object page_size, object page_state, object timeout)

    @staticmethod
    cdef Statement new_from_prepared(CassStatement* cass_statement, object page_size, object page_state, object timeout)

    cdef _set_paging(self, object py_page_size, object py_page_state)
    cdef _set_timeout(self, object timeout)
    cdef _check_bind_error_or_raise(self, CassError error)
    cdef _check_if_prepared_or_raise(self)
