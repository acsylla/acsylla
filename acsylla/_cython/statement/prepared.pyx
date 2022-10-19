cdef class PreparedStatement:

    def __cinit__(self):
        self.cass_prepared = NULL

    def __dealloc__(self):
        cass_prepared_free(self.cass_prepared)

    @staticmethod
    cdef PreparedStatement new_(const CassPrepared* cass_prepared, object timeout, object consistency, object serial_consistency):
        cdef PreparedStatement prepared

        prepared = PreparedStatement()
        prepared.cass_prepared = cass_prepared
        prepared.timeout = timeout
        prepared.consistency = consistency
        prepared.serial_consistency = serial_consistency
        return prepared

    def bind(self, object page_size=None, object page_state=None, timeout=None, consistency=None, serial_consistency=None, execution_profile=None):
        cdef CassStatement* cass_statement
        cdef Statement statement

        cass_statement = cass_prepared_bind(self.cass_prepared)
        statement = Statement.new_from_prepared(
            cass_statement,
            self.cass_prepared,
            page_size,
            page_state,
            timeout or self.timeout,
            consistency or self.consistency,
            serial_consistency or self.serial_consistency,
            execution_profile
        )
        if execution_profile is not None:
            self.set_execution_profile(cass_statement, execution_profile)
        return statement

    cdef set_execution_profile(self, CassStatement* cass_statement, str name):
        if name is None:
            return
        cdef CassError error = cass_statement_set_execution_profile(cass_statement, name.encode())
        raise_if_error(error)
