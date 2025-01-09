cdef class Statement:
    cdef:
        bint prepared
        Session session
        CassStatement* cass_statement
        const CassPrepared* cass_prepared
        public object tracing_enabled
        public object native_types

    @staticmethod
    cdef Statement new_from_string(str statement_str,
                                   object parameters,
                                   object value_types,
                                   object page_size,
                                   object page_state,
                                   object timeout,
                                   object consistency,
                                   object serial_consistency,
                                   object execution_profile,
                                   object native_types,
                                )

    @staticmethod
    cdef Statement new_from_prepared(Session session,
                                     CassStatement* cass_statement,
                                     const CassPrepared* cass_prepared,
                                     object page_size,
                                     object page_state,
                                     object timeout,
                                     object consistency,
                                     object serial_consistency,
                                     object execution_profile,
                                     object native_types,
                                )

    cdef inline get_value_type(self, object value)
