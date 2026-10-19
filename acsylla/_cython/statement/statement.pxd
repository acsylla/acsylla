cdef struct BindOptions:
    # Decimals are written as the text acsylla 1.x wrote: a statement of a session with legacy_types=True, or one
    # without a session
    bint legacy_types
    # A statement without a session, its decimals written as text get a warning
    bint without_session
    # A decimal was bound, a session executes the statement only with its own legacy_types
    bint decimal_bound


cdef class Statement:
    cdef:
        bint prepared
        Session session
        CassStatement* cass_statement
        const CassPrepared* cass_prepared
        public object tracing_enabled
        public object native_types
        BindOptions bind_options

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
                                   Session session,
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

    cdef int _bind(self, int idx, object value, object value_type) except -1
