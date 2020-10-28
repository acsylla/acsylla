cdef class Statement:
    cdef:
        bint prepared
        CassStatement* cass_statement

    @staticmethod
    cdef Statement new_from_string(str statement_str, int parameters, object page_size, object page_state, object timeout, object consistency)

    @staticmethod
    cdef Statement new_from_prepared(CassStatement* cass_statement, object page_size, object page_state, object timeout, object consistency)

    cdef _set_paging(self, object py_page_size, object py_page_state)
    cdef _set_timeout(self, object timeout)
    cdef _set_consistency(self, object consistency)

    cpdef bind(self, int idx, object value)
    cdef inline _bind_null(self, int index)
    cdef inline _bind_int(self, int index, int value)
    cdef inline _bind_float(self, int index, float value)
    cdef inline _bind_bool(self, int index, object value)
    cdef inline _bind_string(self, int index, str value)
    cdef inline _bind_bytes(self, int index, bytes value)
    cdef inline _bind_uuid(self, int index, TypeUUID uuid)

    cpdef bind_by_name(self, str name, object value)
    cdef inline _bind_null_by_name(self, bytes name)
    cdef inline _bind_int_by_name(self, bytes name, int value)
    cdef inline _bind_float_by_name(self, bytes name, float value)
    cdef inline _bind_bool_by_name(self, bytes name, object value)
    cdef inline _bind_string_by_name(self, bytes name, str value)
    cdef inline _bind_bytes_by_name(self, bytes name, bytes value)
    cdef inline _bind_uuid_by_name(self, bytes name, TypeUUID uuid)
