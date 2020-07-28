cdef class Statement:

    def __cinit__(self):
        self.cass_statement = NULL

    def __dealloc__(self):
        cass_statement_free(self.cass_statement)

    @staticmethod
    cdef Statement new_from_string(str statement_str, int parameters):
        cdef Statement statement
        cdef bytes encoded_statement

        encoded_statement = statement_str.encode()

        statement = Statement()
        statement.cass_statement = cass_statement_new_n(
            encoded_statement,
            len(encoded_statement),
            parameters
        )
        return statement

    @staticmethod
    cdef Statement new_from_prepared(CassStatement* cass_statement):
        cdef Statement statement

        statement = Statement()
        statement.cass_statement = cass_statement
        statement.prepared = 1
        return statement

    cdef _check_bind_error_or_raise(self, CassError error):
        if error == CASS_OK:
            return
 
        if error == CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS:
            raise ValueError(f"Index out of band")
        else:
            raise RuntimeError("Error {} trying to bind the statement".format(error))

    def bind_null(self, int index):
        self._check_bind_error_or_raise(
            cass_statement_bind_null(self.cass_statement, index)
        )

    def bind_int(self, int value, int index):
        self._check_bind_error_or_raise(
            cass_statement_bind_int32(self.cass_statement, index, value)
        )

    def bind_float(self, float value, int index):
        self._check_bind_error_or_raise(
            cass_statement_bind_float(self.cass_statement, index, value)
        )

    def bind_bool(self, object value, int index):
        if value is True:
            self._check_bind_error_or_raise(
                cass_statement_bind_bool(self.cass_statement, index, cass_true)
            )
        elif value is False:
            self._check_bind_error_or_raise(
                cass_statement_bind_bool(self.cass_statement, index, cass_false)
            )
        else:
            raise ValueError("Value is not boolean")


    def bind_string(self, str value, int index):
        cdef bytes bytes_value = value.encode()

        self._check_bind_error_or_raise(
            cass_statement_bind_string_n(self.cass_statement, index, bytes_value, len(bytes_value))
        )

    def bind_bytes(self, bytes value, int index):
        self._check_bind_error_or_raise(
            cass_statement_bind_bytes(self.cass_statement, index, <const cass_byte_t*> value, len(value))
        )


def create_statement(str statement_str, int parameters=0):
    cdef Statement statement
    statement = Statement.new_from_string(statement_str, parameters)
    return statement
