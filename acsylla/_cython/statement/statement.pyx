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
        statement.prepared = 0
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
            raise ValueError("Index out of band")
        elif error == CASS_ERROR_LIB_NAME_DOES_NOT_EXIST:
            raise ValueError("Name does not exist")
        else:
            raise RuntimeError("Error {} trying to bind the statement".format(error))

    def bind_null(self, int index):
        self._check_bind_error_or_raise(
            cass_statement_bind_null(self.cass_statement, index)
        )

    def bind_int(self, int index, int value):
        self._check_bind_error_or_raise(
            cass_statement_bind_int32(self.cass_statement, index, value)
        )

    def bind_float(self, int index, float value):
        self._check_bind_error_or_raise(
            cass_statement_bind_float(self.cass_statement, index, value)
        )

    def bind_bool(self, int index, object value):
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


    def bind_string(self, int index, str value):
        cdef bytes bytes_value = value.encode()

        self._check_bind_error_or_raise(
            cass_statement_bind_string_n(self.cass_statement, index, bytes_value, len(bytes_value))
        )

    def bind_bytes(self, int index, bytes value):
        self._check_bind_error_or_raise(
            cass_statement_bind_bytes(self.cass_statement, index, <const cass_byte_t*> value, len(value))
        )

    # following methods are only allowed for statements
    # created using prepared statements

    cdef _check_if_prepared_or_raise(self):
        if self.prepared == 0:
            raise ValueError(
                "Method only availabe for statements created from prepared statements")
 
    def bind_null_by_name(self, str name):
        cdef bytes bytes_name

        self._check_if_prepared_or_raise()

        bytes_name = name.encode()
        self._check_bind_error_or_raise(
            cass_statement_bind_null_by_name_n(
                self.cass_statement, bytes_name, len(bytes_name))
        )

    def bind_int_by_name(self, str name, int value):
        cdef bytes bytes_name

        self._check_if_prepared_or_raise()

        bytes_name = name.encode()
        self._check_bind_error_or_raise(
            cass_statement_bind_int32_by_name_n(
                self.cass_statement, bytes_name, len(bytes_name), value)
        )


    def bind_float_by_name(self, str name, float value):
        cdef bytes bytes_name

        self._check_if_prepared_or_raise()

        bytes_name = name.encode()
        self._check_bind_error_or_raise(
            cass_statement_bind_float_by_name_n(
                self.cass_statement, bytes_name, len(bytes_name), value)
        )


    def bind_bool_by_name(self, str name, object value):
        cdef bytes bytes_name

        self._check_if_prepared_or_raise()

        bytes_name = name.encode()
        if value is True:
            self._check_bind_error_or_raise(
                cass_statement_bind_bool_by_name_n(
                    self.cass_statement, bytes_name, len(bytes_name), cass_true)
            )
        elif value is False:
            self._check_bind_error_or_raise(
                cass_statement_bind_bool_by_name_n(
                    self.cass_statement, bytes_name, len(bytes_name), cass_false)
            )
        else:
            raise ValueError("Value is not boolean")


    def bind_string_by_name(self, str name, str value):
        cdef bytes bytes_name
        cdef bytes bytes_value

        self._check_if_prepared_or_raise()

        bytes_name = name.encode()
        bytes_value = value.encode()

        self._check_bind_error_or_raise(
            cass_statement_bind_string_by_name_n(
                self.cass_statement, bytes_name, len(bytes_name), bytes_value, len(bytes_value)
            )
        )

    def bind_bytes_by_name(self, str name, bytes value):
        cdef bytes bytes_name

        self._check_if_prepared_or_raise()

        bytes_name = name.encode()

        self._check_bind_error_or_raise(
            cass_statement_bind_bytes_by_name_n(
                self.cass_statement,
                bytes_name,
                len(bytes_name),
                <const cass_byte_t*> value,
                len(value)
            )
        )


def create_statement(str statement_str, int parameters=0):
    cdef Statement statement
    statement = Statement.new_from_string(statement_str, parameters)
    return statement
