cdef class Statement:
    cdef:
        bint prepared
        CassStatement* cass_statement
        const CassPrepared* cass_prepared

    @staticmethod
    cdef Statement new_from_string(str statement_str,
                                   int parameters,
                                   object page_size,
                                   object page_state,
                                   object timeout,
                                   object consistency,
                                   object serial_consistency,
                                   str execution_profile)

    @staticmethod
    cdef Statement new_from_prepared(CassStatement* cass_statement,
                                     const CassPrepared* cass_prepared,
                                     object page_size,
                                     object page_state,
                                     object timeout,
                                     object consistency,
                                     object serial_consistency,
                                     str execution_profile)

    cdef const CassDataType* _get_data_type(self, int index)
    cdef const CassDataType* _get_data_type_by_name(self, bytes name)
    cdef CassValueType _get_value_type(self, const CassDataType* data_type)

    cpdef bind(self, int idx, object value)
    cpdef bind_by_name(self, str name, object value)

    cpdef set_timeout(self, object timeout)
    cpdef set_consistency(self, object consistency)
    cpdef set_serial_consistency(self, object consistency)
    cpdef set_page_size(self, object page_size)
    cpdef set_page_state(self, object page_state)

