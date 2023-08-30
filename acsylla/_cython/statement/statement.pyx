from datetime import date
from datetime import datetime
from datetime import time
from datetime import timedelta
from decimal import Decimal
from ipaddress import IPv4Address
from ipaddress import IPv6Address
from uuid import UUID

import asyncio


cdef class Statement:

    def __cinit__(self):
        self.cass_statement = NULL

    def __dealloc__(self):
        cass_statement_free(self.cass_statement)

    async def __aiter__(self):
        if self.prepared == 0:
            raise RuntimeError("Method only availabe for statements created from prepared")

        result = await self.session.execute(self, native_types=self.native_types)
        while True:
            if result.has_more_pages():
                self.set_page_state(result.page_state())
                future_result = asyncio.create_task(
                    self.session.execute(self, native_types=self.native_types))
                await asyncio.sleep(0)
            else:
                future_result = None
            for row in result:
                yield row
            if future_result is not None:
                result = await future_result
            else:
                break

    @staticmethod
    cdef Statement new_from_string(
        str statement_str,
        int parameters,
        object page_size,
        object page_state,
        object timeout,
        object consistency,
        object serial_consistency,
        str execution_profile,
        object native_types,
    ):

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
        statement.native_types
        statement.set_page_size(page_size)
        statement.set_page_state(page_state)
        statement.set_timeout(timeout)
        statement.set_consistency(consistency)
        statement.set_serial_consistency(serial_consistency)
        statement.set_execution_profile(execution_profile)
        return statement

    @staticmethod
    cdef Statement new_from_prepared(
            Session session,
            CassStatement* cass_statement,
            const CassPrepared* cass_prepared,
            object page_size,
            object page_state,
            object timeout,
            object consistency,
            object serial_consistency,
            str execution_profile,
            object native_types,
        ):

        cdef Statement statement

        statement = Statement()
        statement.session = session
        statement.cass_statement = cass_statement
        statement.cass_prepared = cass_prepared
        statement.prepared = 1
        statement.native_types = native_types
        statement.set_page_size(page_size)
        statement.set_page_state(page_state)
        statement.set_timeout(timeout)
        statement.set_consistency(consistency)
        statement.set_serial_consistency(serial_consistency)
        statement.set_execution_profile(execution_profile)
        return statement

    async def execute(self, native_types=None):
        if self.prepared == 0:
            raise RuntimeError("Method only availabe for statements created from prepared")
        return await self.session.execute(self, native_types=native_types)

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

    def set_execute_as(self, name: str) -> None:
        if name is not None:
            error = cass_statement_set_execute_as(self.cass_statement, name.encode())
            raise_if_error(error)

    cpdef bind(self, int idx, object value):
        cdef CassError error = CASS_OK
        cdef const CassDataType* cass_data_type
        cdef CassValueType cass_value_type

        if self.cass_prepared:
            cass_data_type = cass_prepared_parameter_data_type(self.cass_prepared, idx)
            if cass_data_type == NULL:
                raise CassErrorLibIndexOutOfBounds()
            cass_value_type = cass_data_type_type(cass_data_type)

            if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
                raise ValueError(f"Unknown type for column index {idx}")
            elif value is None:
                error = cass_statement_bind_null(self.cass_statement, idx)
            elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
                error = cass_statement_bind_bool(self.cass_statement, idx, as_bool(value))
            elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
                error = cass_statement_bind_int8(self.cass_statement, idx, int(value))
            elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
                error = cass_statement_bind_int16(self.cass_statement, idx, int(value))
            elif cass_value_type == CASS_VALUE_TYPE_INT:
                error = cass_statement_bind_int32(self.cass_statement, idx, int(value))
            elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                                     CASS_VALUE_TYPE_COUNTER):
                error = cass_statement_bind_int64(self.cass_statement, idx, int(value))
            elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
                error =  cass_statement_bind_float(self.cass_statement, idx, float(value))
            elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
                error = cass_statement_bind_double(self.cass_statement, idx, float(value))
            elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
                value, scale = as_cass_decimal(value)
                error = cass_statement_bind_decimal(self.cass_statement, idx, value, len(value), scale)
            elif cass_value_type == CASS_VALUE_TYPE_ASCII:
                error = cass_statement_bind_string(self.cass_statement, idx, as_bytes(value, 'ascii'))
            elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                                     CASS_VALUE_TYPE_VARCHAR):
                error = cass_statement_bind_string(self.cass_statement, idx, as_bytes(value))
            elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                                     CASS_VALUE_TYPE_VARINT,
                                     CASS_VALUE_TYPE_CUSTOM):
                error = cass_statement_bind_bytes(self.cass_statement, idx, as_blob(value), len(value))
            elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                                     CASS_VALUE_TYPE_TIMEUUID):
                error = cass_statement_bind_uuid(self.cass_statement, idx, as_cass_uuid(value))
            elif cass_value_type == CASS_VALUE_TYPE_INET:
                error = cass_statement_bind_inet(self.cass_statement, idx, as_cass_inet(value))
            elif cass_value_type == CASS_VALUE_TYPE_DATE:
                error = cass_statement_bind_uint32(self.cass_statement, idx, as_cass_date(value))
            elif cass_value_type == CASS_VALUE_TYPE_TIME:
                error = cass_statement_bind_int64(self.cass_statement, idx, as_cass_time(value))
            elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
                error = cass_statement_bind_int64(self.cass_statement, idx, as_cass_timestamp(value))
            elif cass_value_type == CASS_VALUE_TYPE_DURATION:
                month, days, nanos = as_cass_duration(value)
                error = cass_statement_bind_duration(self.cass_statement, idx, month, days, nanos)
            elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                                     CASS_VALUE_TYPE_SET,
                                     CASS_VALUE_TYPE_LIST):
                error = bind_collection(self.cass_statement, idx, value, cass_data_type)
            elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
                error = bind_tuple(self.cass_statement, idx, value, cass_data_type)
            elif cass_value_type == CASS_VALUE_TYPE_UDT:
                error = bind_udt(self.cass_statement, idx, value, cass_data_type)
            if error:
                raise_if_error(error)
            return

        if value is None:
            error = cass_statement_bind_null(self.cass_statement, idx)
        # Bool needs to be the first one, since boolean types
        # are implemented using integers.
        elif isinstance(value, bool):
            error = cass_statement_bind_bool(self.cass_statement, idx, as_bool(value))
        elif isinstance(value, int):
            error = cass_statement_bind_int32(self.cass_statement, idx, int(value))
        elif isinstance(value, float):
            error =  cass_statement_bind_float(self.cass_statement, idx, float(value))
        elif isinstance(value, str):
            error = cass_statement_bind_string(self.cass_statement, idx, as_bytes(value))
        elif isinstance(value, bytes):
            error = cass_statement_bind_bytes(self.cass_statement, idx, value, len(value))
        elif isinstance(value, Decimal):
            value, scale = as_cass_decimal(value)
            error = cass_statement_bind_decimal(self.cass_statement, idx, value, len(value), scale)
        elif isinstance(value, UUID):
            error = cass_statement_bind_uuid(self.cass_statement, idx, as_cass_uuid(value))
        elif isinstance(value, (IPv4Address, IPv6Address)):
            error = cass_statement_bind_inet(self.cass_statement, idx, as_cass_inet(value))
        elif isinstance(value, datetime):
            error = cass_statement_bind_int64(self.cass_statement, idx, as_cass_timestamp(value))
        elif isinstance(value, date):
            error = cass_statement_bind_uint32(self.cass_statement, idx, as_cass_date(value))
        elif isinstance(value, time):
            error = cass_statement_bind_int64(self.cass_statement, idx, as_cass_time(value))
        elif isinstance(value, timedelta):
            month, days, nanos = as_cass_duration(value)
            error = cass_statement_bind_duration(self.cass_statement, idx, month, days, nanos)
        elif isinstance(value, (dict, set, list)):
            raise ValueError('Collections types (map, set, list) and UDT type only availabe for statements created from prepared statements')
        elif isinstance(value, tuple):
            raise ValueError('Type "tuple" only availabe for statements created from prepared statements')
        else:
            raise ValueError(f"Value {value} not supported for not prepared statements")

        if error:
            raise_if_error(error)

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

        cass_data_type = cass_prepared_parameter_data_type_by_name(self.cass_prepared, name.encode())
        if cass_data_type == NULL:
            raise CassErrorLibNameDoesNotExist(f"Unknown column: {name}")
        cass_value_type = cass_data_type_type(cass_data_type)

        if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
            raise ValueError(f"Unknown type for column {name}")
        elif value is None:
            error = cass_statement_bind_null_by_name(self.cass_statement, name.encode())
        elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
            error = cass_statement_bind_bool_by_name(self.cass_statement, name.encode(), as_bool(value))
        elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
            error = cass_statement_bind_int8_by_name(self.cass_statement, name.encode(), int(value))
        elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
            error = cass_statement_bind_int16_by_name(self.cass_statement, name.encode(), int(value))
        elif cass_value_type == CASS_VALUE_TYPE_INT:
            error = cass_statement_bind_int32_by_name(self.cass_statement, name.encode(), int(value))
        elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                                 CASS_VALUE_TYPE_COUNTER):
            error = cass_statement_bind_int64_by_name(self.cass_statement, name.encode(), int(value))
        elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
            error = cass_statement_bind_float_by_name(self.cass_statement, name.encode(), float(value))
        elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
            error = cass_statement_bind_double_by_name(self.cass_statement, name.encode(), float(value))
        elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
            value, scale = as_cass_decimal(value)
            error = cass_statement_bind_decimal_by_name(self.cass_statement, name.encode(), value, len(value), scale)
        elif cass_value_type == CASS_VALUE_TYPE_ASCII:
            error = cass_statement_bind_string_by_name(self.cass_statement, name.encode(), as_bytes(value, 'ascii'))
        elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                                 CASS_VALUE_TYPE_VARCHAR):
            error = cass_statement_bind_string_by_name(self.cass_statement, name.encode(), as_bytes(value))
        elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                                 CASS_VALUE_TYPE_VARINT,
                                 CASS_VALUE_TYPE_CUSTOM):
            error = cass_statement_bind_bytes_by_name(self.cass_statement, name.encode(), as_blob(value), len(value))
        elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                                 CASS_VALUE_TYPE_TIMEUUID):
            error = cass_statement_bind_uuid_by_name(self.cass_statement, name.encode(), as_cass_uuid(value))
        elif cass_value_type == CASS_VALUE_TYPE_INET:
            error = cass_statement_bind_inet_by_name(self.cass_statement, name.encode(), as_cass_inet(value))
        elif cass_value_type == CASS_VALUE_TYPE_DATE:
            error = cass_statement_bind_uint32_by_name(self.cass_statement, name.encode(), as_cass_date(value))
        elif cass_value_type == CASS_VALUE_TYPE_TIME:
            error = cass_statement_bind_int64_by_name(self.cass_statement, name.encode(), as_cass_time(value))
        elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
            error = cass_statement_bind_int64_by_name(self.cass_statement, name.encode(), as_cass_timestamp(value))
        elif cass_value_type == CASS_VALUE_TYPE_DURATION:
            month, days, nanos = as_cass_duration(value)
            error = cass_statement_bind_duration_by_name(self.cass_statement, name.encode(), month, days, nanos)
        elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                                 CASS_VALUE_TYPE_SET,
                                 CASS_VALUE_TYPE_LIST):
            error = bind_collection_by_name(self.cass_statement, name.encode(), value, cass_data_type)
        elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
            error = bind_tuple_by_name(self.cass_statement, name.encode(), value, cass_data_type)
        elif cass_value_type == CASS_VALUE_TYPE_UDT:
            error = bind_udt_by_name(self.cass_statement, name.encode(), value, cass_data_type)
        if error:
            raise_if_error(error)

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
    str execution_profile=None,
    object native_types=False):
    cdef Statement statement
    statement = Statement.new_from_string(
        statement_str,
        parameters,
        page_size,
        page_state,
        timeout,
        consistency,
        serial_consistency,
        execution_profile,
        native_types,
    )
    return statement
