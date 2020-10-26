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

    cdef inline _bind_null(self, int index):
        cdef CassError error
        error = cass_statement_bind_null(self.cass_statement, index)
        raise_if_error(error)

    cdef inline _bind_int(self, int index, int value):
        cdef CassError error
        error = cass_statement_bind_int32(self.cass_statement, index, value)
        raise_if_error(error)

    cdef inline _bind_float(self, int index, float value):
        cdef CassError error
        error = cass_statement_bind_float(self.cass_statement, index, value)
        raise_if_error(error)

    cdef inline _bind_bool(self, int index, object value):
        cdef CassError error
        if value is True:
            error = cass_statement_bind_bool(self.cass_statement, index, cass_true)
        else:
            error = cass_statement_bind_bool(self.cass_statement, index, cass_false)
        raise_if_error(error)

    cdef inline _bind_string(self, int index, str value):
        cdef CassError error
        cdef bytes bytes_value = value.encode()

        error = cass_statement_bind_string_n(
            self.cass_statement, index, bytes_value, len(bytes_value)
        )
        raise_if_error(error)

    cdef inline _bind_bytes(self, int index, bytes value):
        cdef CassError error
        error = cass_statement_bind_bytes(
            self.cass_statement, index, <const cass_byte_t*> value, len(value)
        )
        raise_if_error(error)

    cdef inline _bind_null_by_name(self, bytes name):
        cdef CassError error
        error = cass_statement_bind_null_by_name_n(self.cass_statement, name, len(name))
        raise_if_error(error)

    cdef inline _bind_int_by_name(self, bytes name, int value):
        cdef CassError error
        error = cass_statement_bind_int32_by_name_n(self.cass_statement, name, len(name), value)
        raise_if_error(error)

    cdef inline _bind_float_by_name(self, bytes name, float value):
        cdef CassError error
        error = cass_statement_bind_float_by_name_n(
            self.cass_statement, name, len(name), value)
        raise_if_error(error)

    cdef inline _bind_bool_by_name(self, bytes name, object value):
        cdef CassError error
        if value is True:
            error = cass_statement_bind_bool_by_name_n(
                self.cass_statement, name, len(name), cass_true)
        else:
            error = cass_statement_bind_bool_by_name_n(
                self.cass_statement, name, len(name), cass_false)
        raise_if_error(error)

    cdef inline _bind_string_by_name(self, bytes name, str value):
        cdef CassError error
        cdef bytes bytes_value

        bytes_value = value.encode()

        error = cass_statement_bind_string_by_name_n(
            self.cass_statement, name, len(name), bytes_value, len(bytes_value))
        raise_if_error(error)

    cdef inline _bind_bytes_by_name(self, bytes name, bytes value):
        cdef CassError error
        error = cass_statement_bind_bytes_by_name_n(
            self.cass_statement,
            name,
            len(name),
            <const cass_byte_t*> value,
            len(value)
        )
        raise_if_error(error)

    cpdef bind(self, int idx, object value):
        if value is None:
            self._bind_null(idx)
        elif isinstance(value, int):
            self._bind_int(idx, value)
        elif isinstance(value, float):
            self._bind_float(idx, value)
        elif isinstance(value, bool):
            self._bind_bool(idx, value)
        elif isinstance(value, str):
            self._bind_string(idx, value)
        elif isinstance(value, bytes):
            self._bind_bytes(idx, value)
        else:
            raise ValueError("Value {} not supported".format(value))


    def bind_list(self, list values):
        cdef int idx
        cdef object value

        idx = 0
        for value in values:
            self.bind(idx, value)
            idx += 1

    cpdef bind_by_name(self, str name, object value):
        if self.prepared == 0:
            raise ValueError(
                "Method only availabe for statements created from prepared statements")

        if value is None:
            self._bind_null_by_name(name.encode())
        elif isinstance(value, int):
            self._bind_int_by_name(name.encode(), value)
        elif isinstance(value, float):
            self._bind_float_by_name(name.encode(), value)
        elif isinstance(value, bool):
            self._bind_bool_by_name(name.encode(), value)
        elif isinstance(value, str):
            self._bind_string_by_name(name.encode(), value)
        elif isinstance(value, bytes):
            self._bind_bytes_by_name(name.encode(), value)
        else:
            raise ValueError("Value {} not supported".format(value))

    def bind_dict(self, dict values):
        cdef str name
        cdef object value

        if self.prepared == 0:
            raise ValueError(
                "Method only availabe for statements created from prepared statements")

        for name, value in values.items():
            self.bind_by_name(name, value)


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
