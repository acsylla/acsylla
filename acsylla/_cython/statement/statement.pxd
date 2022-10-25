cdef class Statement:
    cdef:
        bint prepared
        CassStatement* cass_statement
        const CassPrepared* cass_prepared
        public object tracing_enabled

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
