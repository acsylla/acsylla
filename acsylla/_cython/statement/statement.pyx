cdef class Statement:

    def __cinit__(self):
        self.cass_statement = NULL

    def __dealloc__(self):
        cass_statement_free(self.cass_statement)

    def __init__(self, str statement, int parameters=0):
        cdef bytes encoded_statement
        encoded_statement = statement.encode()
        self.parameters = parameters
        self.cass_statement = cass_statement_new_n(
            encoded_statement,
            len(encoded_statement),
            parameters
        )

    cdef _check_index_or_raise(self, index):
        if index >= self.parameters:
            raise ValueError(f"Index {index} has to be lower than {self.parameters}")

    cdef _check_bind_error_or_raise(self, CassError error):
        if error != CASS_OK:
            raise RuntimeError("Error {} trying to bind the statement".format(error))

    def bind_null(self, int index):
        self._check_index_or_raise(index)
        self._check_bind_error_or_raise(
            cass_statement_bind_null(self.cass_statement, index)
        )

    def bind_int(self, int value, int index):
        self._check_index_or_raise(index)
        self._check_bind_error_or_raise(
            cass_statement_bind_int32(self.cass_statement, index, value)
        )

    def bind_float(self, float value, int index):
        self._check_index_or_raise(index)
        self._check_bind_error_or_raise(
            cass_statement_bind_float(self.cass_statement, index, value)
        )

    def bind_bool(self, object value, int index):
        self._check_index_or_raise(index)

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

        self._check_index_or_raise(index)
        self._check_bind_error_or_raise(
            cass_statement_bind_string_n(self.cass_statement, index, bytes_value, len(bytes_value))
        )

    def bind_bytes(self, bytes value, int index):
        self._check_index_or_raise(index)
        self._check_bind_error_or_raise(
            cass_statement_bind_bytes(self.cass_statement, index, <const cass_byte_t*> value, len(value))
        )
