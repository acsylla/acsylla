cdef class PreparedStatement:

    def __cinit__(self):
        self.cass_prepared = NULL

    def __dealloc__(self):
        cass_prepared_free(self.cass_prepared)

    @staticmethod
    cdef PreparedStatement new_(const CassPrepared* cass_prepared):
        cdef PreparedStatement prepared

        prepared = PreparedStatement()
        prepared.cass_prepared = cass_prepared
        return prepared

    def bind(self):
        cdef CassStatement* cass_statement
        cdef Statement statement

        cass_statement = cass_prepared_bind(self.cass_prepared)
        statement = Statement.new_from_prepared(cass_statement)
        return statement
