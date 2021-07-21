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
            const CassPrepared* cass_prepared,
            object page_size,
            object page_state,
            object timeout,
            object consistency):

        cdef Statement statement

        statement = Statement()
        statement.cass_statement = cass_statement
        statement.cass_prepared = cass_prepared
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

    cdef CassValueType _get_data_type(self, int index):
        cdef const CassDataType * data_type
        cdef CassValueType cass_type

        if self.cass_prepared:
            data_type = cass_prepared_parameter_data_type(self.cass_prepared, index)
            cass_type = cass_data_type_type(data_type)
            return cass_type
        else:
            raise ValueError(
                "Method only availabe for statements created from prepared statements")

    cdef CassValueType _get_data_type_by_name(self, bytes name):
        cdef const CassDataType * data_type
        cdef CassValueType cass_type

        if self.cass_prepared:
            data_type = cass_prepared_parameter_data_type_by_name(self.cass_prepared, name)
            cass_type = cass_data_type_type(data_type)
            return cass_type
        else:
            raise ValueError(
                "Method only availabe for statements created from prepared statements")

    cpdef bind(self, int idx, object value):
        from uuid import UUID
        from decimal import Decimal
        from ipaddress import IPv4Address, IPv6Address
        from datetime import date, datetime, time, timedelta
        cdef CassValueType cass_type

        try:
            bind_null(self.cass_statement, idx)
        except CassErrorLibIndexOutOfBounds:
            raise CassErrorLibIndexOutOfBounds()

        if value is None:
            return

        if self.cass_prepared:
            cass_type = self._get_data_type(idx)
            if cass_type == CASS_VALUE_TYPE_UNKNOWN:
                raise ValueError(f"Unknown type for column index {idx}")
            elif cass_type == CASS_VALUE_TYPE_BOOLEAN:
                bind_bool(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_TINY_INT:
                bind_int8(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_SMALL_INT:
                bind_int16(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_INT:
                bind_int32(self.cass_statement, idx, value)
            elif cass_type in (CASS_VALUE_TYPE_BIGINT,
                               CASS_VALUE_TYPE_COUNTER):
                bind_int64(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_FLOAT:
                bind_float(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_DOUBLE:
                bind_double(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_DECIMAL:
                bind_decimal(self.cass_statement, idx, value)
            elif cass_type in (CASS_VALUE_TYPE_ASCII,
                               CASS_VALUE_TYPE_TEXT,
                               CASS_VALUE_TYPE_VARCHAR):
                bind_string(self.cass_statement, idx, value)
            elif cass_type in (CASS_VALUE_TYPE_BLOB,
                               CASS_VALUE_TYPE_VARINT,
                               CASS_VALUE_TYPE_CUSTOM):
                bind_bytes(self.cass_statement, idx, value)
            elif cass_type in (CASS_VALUE_TYPE_UUID,
                               CASS_VALUE_TYPE_TIMEUUID):
                bind_uuid(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_INET:
                bind_inet(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_DATE:
                bind_date(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_TIME:
                bind_time(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_TIMESTAMP:
                bind_timestamp(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_DURATION:
                bind_duration(self.cass_statement, idx, value)
            elif cass_type == CASS_VALUE_TYPE_MAP:
                bind_map(self.cass_statement, idx, value)
            return

        # Bool needs to be the first one, since boolean types
        # are implemented using integers.
        if isinstance(value, bool):
            bind_bool(self.cass_statement, idx, value)
        elif isinstance(value, int):
            bind_int32(self.cass_statement, idx, value)
        elif isinstance(value, float):
            bind_float(self.cass_statement, idx, value)
        elif isinstance(value, str):
            bind_string(self.cass_statement, idx, value)
        elif isinstance(value, bytes):
            bind_bytes(self.cass_statement, idx, value)
        elif isinstance(value, Decimal):
            bind_decimal(self.cass_statement, idx, value)
        elif isinstance(value, (TypeUUID, UUID)):
            bind_uuid(self.cass_statement, idx, value)
        elif isinstance(value, (IPv4Address, IPv6Address)):
            bind_inet(self.cass_statement, idx, value)
        elif isinstance(value, datetime):
            bind_timestamp(self.cass_statement, idx, value)
        elif isinstance(value, date):
            bind_date(self.cass_statement, idx, value)
        elif isinstance(value, time):
            bind_time(self.cass_statement, idx, value)
        elif isinstance(value, timedelta):
            bind_duration(self.cass_statement, idx, value)
        elif isinstance(value, dict):
            bind_map(self.cass_statement, idx, value)
        else:
            raise ValueError(f"Value {value} not supported")


    def bind_list(self, list values):
        cdef int idx
        cdef object value

        idx = 0
        for value in values:
            self.bind(idx, value)
            idx += 1

    cpdef bind_by_name(self, str name, object value):
        cdef CassValueType cass_type

        if self.prepared == 0:
            raise ValueError(
                "Method only availabe for statements created from prepared statements")
        try:
            bind_null_by_name(self.cass_statement, name.encode())
        except CassErrorLibNameDoesNotExist:
            raise CassErrorLibNameDoesNotExist()

        if value is None:
            return

        cass_type = self._get_data_type_by_name(name.encode())

        if cass_type == CASS_VALUE_TYPE_UNKNOWN:
            raise ValueError(f"Unknown type for column {name}")
        elif cass_type == CASS_VALUE_TYPE_BOOLEAN:
            bind_bool_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_TINY_INT:
            bind_int8_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_SMALL_INT:
            bind_int16_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_INT:
            bind_int32_by_name(self.cass_statement, name.encode(), value)
        elif cass_type in (CASS_VALUE_TYPE_BIGINT,
                           CASS_VALUE_TYPE_COUNTER):
            bind_int64_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_FLOAT:
            bind_float_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_DOUBLE:
            bind_double_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_DECIMAL:
            bind_decimal_by_name(self.cass_statement, name.encode(), value)
        elif cass_type in (CASS_VALUE_TYPE_ASCII,
                           CASS_VALUE_TYPE_TEXT,
                           CASS_VALUE_TYPE_VARCHAR):
            bind_string_by_name(self.cass_statement, name.encode(), value)
        elif cass_type in (CASS_VALUE_TYPE_BLOB,
                           CASS_VALUE_TYPE_VARINT,
                           CASS_VALUE_TYPE_CUSTOM):
            bind_bytes_by_name(self.cass_statement, name.encode(), value)
        elif cass_type in (CASS_VALUE_TYPE_UUID,
                           CASS_VALUE_TYPE_TIMEUUID):
            bind_uuid_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_INET:
            bind_inet_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_DATE:
            bind_date_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_TIME:
            bind_time_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_TIMESTAMP:
            bind_timestamp_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_DURATION:
            bind_duration_by_name(self.cass_statement, name.encode(), value)
        elif cass_type == CASS_VALUE_TYPE_MAP:
            bind_map_by_name(self.cass_statement, name.encode(), value)
        #
        # elif cass_type == CASS_VALUE_TYPE_LIST:
        #
        # elif cass_type == CASS_VALUE_TYPE_SET:
        #
        # elif cass_type == CASS_VALUE_TYPE_UDT:
        #
        # elif cass_type == CASS_VALUE_TYPE_TUPLE:

        else:
            # raise ValueError("Value {} not supported".format(value))
            raise ValueError(f"Type {cass_type} not supported")

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
