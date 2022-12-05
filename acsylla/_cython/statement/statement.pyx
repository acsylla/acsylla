from datetime import date
from datetime import datetime
from datetime import time
from datetime import timedelta
from decimal import Decimal
from ipaddress import IPv4Address
from ipaddress import IPv6Address
from uuid import UUID


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
        object consistency,
        object serial_consistency,
        str execution_profile):

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
        statement.set_page_size(page_size)
        statement.set_page_state(page_state)
        statement.set_timeout(timeout)
        statement.set_consistency(consistency)
        statement.set_serial_consistency(serial_consistency)
        statement.set_execution_profile(execution_profile)
        return statement

    @staticmethod
    cdef Statement new_from_prepared(
            CassStatement* cass_statement,
            const CassPrepared* cass_prepared,
            object page_size,
            object page_state,
            object timeout,
            object consistency,
            object serial_consistency,
            str execution_profile):

        cdef Statement statement

        statement = Statement()
        statement.cass_statement = cass_statement
        statement.cass_prepared = cass_prepared
        statement.prepared = 1
        statement.set_page_size(page_size)
        statement.set_page_state(page_state)
        statement.set_timeout(timeout)
        statement.set_consistency(consistency)
        statement.set_serial_consistency(serial_consistency)
        statement.set_execution_profile(execution_profile)
        return statement

    def add_key_index(self, int index):
        error = cass_statement_add_key_index(self.cass_statement, index)
        raise_if_error(error)

    def reset_parameters(self, int count):
        error = cass_statement_reset_parameters(self.cass_statement, count)
        raise_if_error(error)

    def set_page_size(self, page_size: int):
        if page_size is not None:
            error = cass_statement_set_paging_size(self.cass_statement, page_size)
            raise_if_error(error)

    def set_page_state(self, bytes page_state):
        if page_state is not None:
            error = cass_statement_set_paging_state_token(self.cass_statement, page_state, len(page_state))
            raise_if_error(error)

    def set_timeout(self, object timeout):
        if timeout is not None:
            timeout_ms = int(timeout * 1000)
            error = cass_statement_set_request_timeout(self.cass_statement, timeout_ms)
            raise_if_error(error)

    def set_consistency(self, object consistency):
        cdef CassConsistency cass_consistency
        if consistency is not None:
            cass_consistency = consistency.value
            error = cass_statement_set_consistency(self.cass_statement, cass_consistency)
            raise_if_error(error)

    def set_serial_consistency(self, object consistency):
        cdef CassConsistency cass_consistency
        if consistency is not None:
            cass_consistency = consistency.value
            error = cass_statement_set_serial_consistency(self.cass_statement, cass_consistency)
            raise_if_error(error)
    def set_timestamp(self, timestamp: int):
        if timestamp is not None:
            error = cass_statement_set_timestamp(self.cass_statement, timestamp)
            raise_if_error(error)

    def set_is_idempotent(self, is_idempotent: bool):
        if is_idempotent is not None:
            error = cass_statement_set_is_idempotent(self.cass_statement, is_idempotent)
            raise_if_error(error)

    def set_retry_policy(self, retry_policy: str, retry_policy_logging: bool = False):
        cdef CassRetryPolicy* cass_policy
        cdef CassRetryPolicy* cass_log_policy
        if retry_policy is not None:
            if retry_policy == 'default':
                cass_policy = cass_retry_policy_default_new()
            elif retry_policy == 'fallthrough':
                cass_policy = cass_retry_policy_fallthrough_new()
            else:
                raise ValueError("Retry policy must be 'default' or 'fallthrough'")
            if retry_policy_logging is True:
                cass_log_policy = cass_retry_policy_logging_new(cass_policy)
                error = cass_statement_set_retry_policy(self.cass_statement, cass_log_policy)
                raise_if_error(error)
                cass_retry_policy_free(cass_log_policy)
            else:
                error = cass_statement_set_retry_policy(self.cass_statement, cass_policy)
                raise_if_error(error)
            cass_retry_policy_free(cass_policy)

    def set_tracing(self, enabled: bool = None):
        if enabled is not None:
            error = cass_statement_set_tracing(self.cass_statement, enabled)
            raise_if_error(error)
            self.tracing_enabled = enabled

    def set_host(self, host: str, port: int = 9042):
        if host is not None:
            error = cass_statement_set_host(self.cass_statement, host.encode(), port)
            raise_if_error(error)

    def set_execution_profile(self, name: str) -> None:
        if name is not None:
            error = cass_statement_set_execution_profile(self.cass_statement, name.encode())
            raise_if_error(error)

    cdef const CassDataType* _get_data_type(self, int index):
        cdef const CassDataType* data_type

        if self.cass_prepared:
            data_type = cass_prepared_parameter_data_type(self.cass_prepared, index)
            return data_type
        else:
            raise ValueError(
                "Method only availabe for statements created from prepared statements")

    cdef const CassDataType* _get_data_type_by_name(self, bytes name):
        cdef const CassDataType* data_type

        if self.cass_prepared:
            data_type = cass_prepared_parameter_data_type_by_name(self.cass_prepared, name)
            return data_type
        else:
            raise ValueError(
                "Method only availabe for statements created from prepared statements")

    cdef CassValueType _get_value_type(self, const CassDataType* data_type):
        cdef CassValueType cass_value_type
        cass_value_type = cass_data_type_type(data_type)
        return cass_value_type

    cpdef bind(self, int idx, object value):
        cdef const CassDataType* cass_data_type
        cdef CassValueType cass_value_type

        try:
            bind_null(self.cass_statement, idx)
        except CassErrorLibIndexOutOfBounds:
            raise CassErrorLibIndexOutOfBounds()

        if value is None:
            return

        if self.cass_prepared:
            cass_data_type = self._get_data_type(idx)
            cass_value_type = self._get_value_type(cass_data_type)

            if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
                raise ValueError(f"Unknown type for column index {idx}")
            elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
                bind_bool(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
                bind_int8(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
                bind_int16(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_INT:
                bind_int32(self.cass_statement, idx, value)
            elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                               CASS_VALUE_TYPE_COUNTER):
                bind_int64(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
                bind_float(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
                bind_double(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
                bind_decimal(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_ASCII:
                bind_ascii_string(self.cass_statement, idx, value)
            elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                                     CASS_VALUE_TYPE_VARCHAR):
                bind_string(self.cass_statement, idx, value)
            elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                               CASS_VALUE_TYPE_VARINT,
                               CASS_VALUE_TYPE_CUSTOM):
                bind_bytes(self.cass_statement, idx, value)
            elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                               CASS_VALUE_TYPE_TIMEUUID):
                bind_uuid(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_INET:
                bind_inet(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_DATE:
                bind_date(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_TIME:
                bind_time(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
                bind_timestamp(self.cass_statement, idx, value)
            elif cass_value_type == CASS_VALUE_TYPE_DURATION:
                bind_duration(self.cass_statement, idx, value)
            elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                                     CASS_VALUE_TYPE_SET,
                                     CASS_VALUE_TYPE_LIST):
                bind_collection(self.cass_statement, idx, value, cass_data_type)
            elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
                bind_tuple(self.cass_statement, idx, value, cass_data_type)
            elif cass_value_type == CASS_VALUE_TYPE_UDT:
                bind_udt(self.cass_statement, idx, value, cass_data_type)
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
        elif isinstance(value, UUID):
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
        elif isinstance(value, (dict, set, list)):
            raise ValueError('Collections types (map, set, list) and UDT type only availabe for statements created from prepared statements')
        elif isinstance(value, tuple):
            raise ValueError('Type "tuple" only availabe for statements created from prepared statements')
        else:
            raise ValueError(f"Value {value} not supported for not prepared statements")

    def bind_list(self, list values):
        cdef int idx
        cdef object value

        idx = 0
        for value in values:
            self.bind(idx, value)
            idx += 1

    cpdef bind_by_name(self, str name, object value):
        cdef const CassDataType* cass_data_type
        cdef CassValueType cass_value_type

        if self.prepared == 0:
            raise ValueError("Method only availabe for statements created from prepared statements")

        bind_null_by_name(self.cass_statement, name.encode())

        if value is None:
            return

        cass_data_type = self._get_data_type_by_name(name.encode())
        cass_value_type = self._get_value_type(cass_data_type)

        if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
            raise ValueError(f"Unknown type for column {name}")
        elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
            bind_bool_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
            bind_int8_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
            bind_int16_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_INT:
            bind_int32_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                                 CASS_VALUE_TYPE_COUNTER):
            bind_int64_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
            bind_float_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
            bind_double_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
            bind_decimal_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_ASCII:
            bind_ascii_string_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                                 CASS_VALUE_TYPE_VARCHAR):
            bind_string_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                                 CASS_VALUE_TYPE_VARINT,
                                 CASS_VALUE_TYPE_CUSTOM):
            bind_bytes_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                                 CASS_VALUE_TYPE_TIMEUUID):
            bind_uuid_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_INET:
            bind_inet_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_DATE:
            bind_date_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_TIME:
            bind_time_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
            bind_timestamp_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type == CASS_VALUE_TYPE_DURATION:
            bind_duration_by_name(self.cass_statement, name.encode(), value)
        elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                                 CASS_VALUE_TYPE_SET,
                                 CASS_VALUE_TYPE_LIST):
            bind_collection_by_name(self.cass_statement, name.encode(), value, cass_data_type)
        elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
            bind_tuple_by_name(self.cass_statement, name.encode(), value, cass_data_type)
        elif cass_value_type == CASS_VALUE_TYPE_UDT:
            bind_udt_by_name(self.cass_statement, name.encode(), value, cass_data_type)
        else:
            raise ValueError(f"Type {cass_value_type} not supported")

    def bind_dict(self, dict values):
        cdef str name
        cdef object value

        if self.prepared == 0:
            raise ValueError("Method only availabe for statements created from prepared statements")

        for name, value in values.items():
            self.bind_by_name(name, value)


def create_statement(
    str statement_str,
    int parameters=0,
    object page_size=None,
    object page_state=None,
    object timeout=None,
    object consistency=None,
    object serial_consistency=None,
    str execution_profile=None):
    cdef Statement statement
    statement = Statement.new_from_string(
        statement_str,
        parameters,
        page_size,
        page_state,
        timeout,
        consistency,
        serial_consistency,
        execution_profile
    )
    return statement
