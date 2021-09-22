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

    def bind(self, object page_size=None, object page_state=None):
        cdef CassStatement* cass_statement
        cdef Statement statement

        cass_statement = cass_prepared_bind(self.cass_prepared)
        statement = Statement.new_from_prepared(
            cass_statement,
            self.cass_prepared,
            page_size,
            page_state,
            self.timeout,
            self.consistency,
            self.serial_consistency,
        )
        return statement
