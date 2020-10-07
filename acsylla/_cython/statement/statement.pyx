cdef class Statement:

    def __cinit__(self):
        self.cass_statement = NULL

    def __dealloc__(self):
        cass_statement_free(self.cass_statement)

    @staticmethod
    cdef Statement new_from_string(
        str statement_str,
        int parameters,
        object page_size,
        object page_state,
        object timeout,
        object consistency):

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
        statement._set_paging(page_size, page_state)
        statement._set_timeout(timeout)
        statement._set_consistency(consistency)
        return statement

    @staticmethod
    cdef Statement new_from_prepared(
            CassStatement* cass_statement,
            object page_size,
            object page_state,
            object timeout,
            object consistency):

        cdef Statement statement

        statement = Statement()
        statement.cass_statement = cass_statement
        statement.prepared = 1
        statement._set_paging(page_size, page_state)
        statement._set_timeout(timeout)
        statement._set_consistency(consistency)
        return statement

    cdef _set_paging(self, object py_page_size, object py_page_state):
        cdef CassError error
        cdef int page_size
        cdef int length
        cdef char* page_state = NULL

        if py_page_size is not None:
            page_size = py_page_size
            error = cass_statement_set_paging_size(self.cass_statement, page_size)
            if error != CASS_OK:
                raise RuntimeError("Error {} trying to set page size".format(error))

        if py_page_state is not None:
            page_state = py_page_state
            length = len(py_page_state)
            error = cass_statement_set_paging_state_token(
                self.cass_statement, page_state, length);
            if error != CASS_OK:
                raise RuntimeError("Error {} trying to set page token state".format(error))

    cdef _set_timeout(self, object timeout):
        cdef CassError error
        cdef int timeout_ms

        if timeout is None:
            return

        timeout_ms = int(timeout * 1000)
        error = cass_statement_set_request_timeout(self.cass_statement, timeout_ms)
        if error != CASS_OK:
            raise RuntimeError("Error {} trying to set the timeout".format(error))

    cdef _set_consistency(self, object consistency):
        cdef CassError error
        cdef CassConsistency cass_consistency

        if consistency is None:
            return

        cass_consistency = consistency.value
        error = cass_statement_set_consistency(self.cass_statement, cass_consistency)
        raise_if_error(error)


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
    def bind_uuid_by_name(self, str name, str value):
        cdef CassUuid uuid
        cdef bytes bytes_value
        cdef bytes bytes_name

        self._check_if_prepared_or_raise()

        bytes_value = value.encode()
        bytes_name = name.encode()

        cass_uuid_from_string(bytes_value, &uuid)
        self._check_bind_error_or_raise(
            cass_statement_bind_uuid_by_name_n(
                self.cass_statement,
                bytes_name,
                len(bytes_name),
                uuid)
        )

    def bind_uuid(self, int index, str value):
        cdef CassUuid uuid
        cdef bytes bytes_value = value.encode()

        cass_uuid_from_string(bytes_value, &uuid)
        self._check_bind_error_or_raise(
            cass_statement_bind_uuid(self.cass_statement, index, uuid)
        )


def create_statement(
    str statement_str,
    int parameters=0,
    object page_size=None,
    object page_state=None,
    object timeout=None,
    object consistency=None):
    cdef Statement statement
    statement = Statement.new_from_string(
        statement_str,
        parameters,
        page_size,
        page_state,
        timeout,
        consistency
    )
    return statement
