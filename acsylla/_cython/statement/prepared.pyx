cdef class PreparedStatement:

    def __cinit__(self):
        self.cass_prepared = NULL

    def __dealloc__(self):
        cass_prepared_free(self.cass_prepared)

    @staticmethod
    cdef PreparedStatement new_(Session session, const CassPrepared* cass_prepared, object timeout, object consistency, object serial_consistency, object execution_profile, object native_types):
        cdef PreparedStatement prepared

        prepared = PreparedStatement()
        prepared.session = session
        prepared.cass_prepared = cass_prepared
        prepared.timeout = timeout
        prepared.consistency = consistency
        prepared.serial_consistency = serial_consistency
        prepared.execution_profile = execution_profile
        prepared.native_types = native_types
        return prepared

    def bind(self, object parameters=None, object page_size=None, object page_state=None, timeout=None, consistency=None, serial_consistency=None, execution_profile=None, native_types=None):
        cdef CassStatement* cass_statement
        cdef Statement statement
        execution_profile = execution_profile or self.execution_profile
        cass_statement = cass_prepared_bind(self.cass_prepared)
        statement = Statement.new_from_prepared(
            self.session,
            cass_statement,
            self.cass_prepared,
            page_size,
            page_state,
            timeout or self.timeout,
            consistency or self.consistency,
            serial_consistency or self.serial_consistency,
            execution_profile,
            native_types or self.native_types,
        )
        if parameters is not None:
            if isinstance(parameters, list):
                statement.bind_list(parameters, None)
            elif isinstance(parameters, tuple):
                statement.bind_tuple(parameters, None)
            elif isinstance(parameters, dict):
                statement.bind_dict(parameters, None)
            else:
                raise ValueError(f'`parameters` must be `list`, `tuple` or `dict` but not {type(parameters)}')
        return statement

    def set_execution_profile(self, name):
        self.execution_profile = name

    def __call__(self, object parameters=None, object page_size=None, object page_state=None, timeout=None, consistency=None, serial_consistency=None, execution_profile=None, native_types=None):
        return self.bind(parameters, page_size, page_state, timeout, consistency, serial_consistency, execution_profile, native_types)
