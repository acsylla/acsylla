cdef inline bind_null(CassStatement* statement, int index):
    cdef CassError error
    error = cass_statement_bind_null(statement, index)
    raise_if_error(error)

cdef inline bind_null_by_name(CassStatement* statement, bytes name):
    cdef CassError error
    error = cass_statement_bind_null_by_name(statement, name)
    raise_if_error(error)

# CASS_VALUE_TYPE_BOOLEAN
cdef inline bind_bool(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_bool(statement, index, cass_true if value else cass_false)
    raise_if_error(error)

cdef inline bind_bool_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_bool_by_name(statement, name, cass_true if value else cass_false)

# CASS_VALUE_TYPE_TINY_INT
cdef get_int8(object value):
    if isinstance(value, float) or (isinstance(value, str) and value.isdigit()):
        value = int(value)
    elif not isinstance(value, int):
        raise ValueError(f'Value "{value}" is not int8')
    if value < -128 or value > 127:
        raise OverflowError(f'Value int8 must be between -128 and 127 got {value}')
    return <cass_int8_t>value

cdef inline bind_int8(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_int8(statement, index, get_int8(value))
    raise_if_error(error)

cdef inline bind_int8_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_int8_by_name(statement, name, get_int8(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_SMALL_INT
cdef get_int16(object value):
    if isinstance(value, float) or (isinstance(value, str) and value.isdigit()):
        value = int(value)
    elif not isinstance(value, int):
        raise ValueError(f'Value "{value}" is not int16')
    if value < -32768 or value > 32767:
        raise OverflowError(f'Value int16 must be between -32768 and 32767 got {value}')
    return <cass_int16_t>value

cdef inline bind_int16(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_int16(statement, index, get_int16(value))
    raise_if_error(error)

cdef inline bind_int16_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_int8_by_name(statement, name, get_int16(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_INT
cdef get_int32(object value):
    if isinstance(value, float) or (isinstance(value, str) and value.isdigit()):
        value = int(value)
    elif not isinstance(value, int):
        raise ValueError(f'Value "{value}" is not int32')
    if value < -2147483648 or value > 2147483647:
        raise OverflowError(f'Value int32 must be between -2147483648 and 2147483647 got {value}')
    return value

cdef bind_int32(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_int32(statement, index, <cass_int32_t>get_int32(value))
    raise_if_error(error)

cdef bind_int32_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_int32_by_name(statement, name, get_int32(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_BIGINT
cdef get_int64(object value):
    if isinstance(value, float) or (isinstance(value, str) and value.isdigit()):
        value = int(value)
    elif not isinstance(value, int):
        raise ValueError(f'Value "{value}" is not int64')
    if value < -9223372036854775808 or value > 9223372036854775807:
        raise OverflowError(f'Value int64 must be between -9223372036854775808 and 9223372036854775807 got {value}')

    return value

cdef inline bind_int64(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_int64(statement, index, get_int64(value))
    raise_if_error(error)

cdef inline bind_int64_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_int64_by_name(statement, name, get_int64(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_FLOAT
cdef get_float(object value):
    from decimal import Decimal
    if isinstance(value, (int, Decimal)) or (isinstance(value, str) and value.isdigit()):
        value = float(value)
    elif not isinstance(value, float):
        raise ValueError(f'Value "{value}" is not float')
    return <cass_float_t>value

cdef inline bind_float(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_float(statement, index, get_float(value))
    raise_if_error(error)

cdef inline bind_float_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_float_by_name(statement, name, get_float(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_DECIMAL
cdef tuple get_cass_decimal(object value):
    from decimal import Decimal
    cdef object t
    cdef cass_int32_t scale
    if not isinstance(value, Decimal):
        value = Decimal(value)
    t = value.as_tuple()
    scale = len(t.digits[len(t.digits[:t.exponent]):])
    value = str(value).encode()
    return value, scale

cdef inline bind_decimal(CassStatement* statement, int index, object value):
    cdef CassError error
    value, scale = get_cass_decimal(value)
    error = cass_statement_bind_decimal(statement, index, <const cass_byte_t*> value, len(value), scale)
    raise_if_error(error)

cdef inline bind_decimal_by_name(CassStatement* statement, bytes name, object value):
    value, scale = get_cass_decimal(value)
    error = cass_statement_bind_decimal_by_name(statement, name, <const cass_byte_t*> value, len(value), scale)
    raise_if_error(error)

# CASS_VALUE_TYPE_DOUBLE
cdef inline bind_double(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_double(statement, index, <cass_double_t>get_float(value))
    raise_if_error(error)

cdef inline bind_double_by_name(CassStatement* statement, bytes name, double value):
    cdef CassError error
    error = cass_statement_bind_double_by_name(statement, name, value)
    raise_if_error(error)

# CASS_VALUE_TYPE_ASCII
cdef get_ascii(object value):
    if isinstance(value, str) and value.isascii():
        return value.encode()
    else:
        raise ValueError(f'Value "{value}" is not ascii string')

cdef inline bind_ascii_string(CassStatement* statement, int index, str value):
    cdef CassError error
    error = cass_statement_bind_string(statement, index, get_ascii(value))
    raise_if_error(error)

cdef inline bind_ascii_string_by_name(CassStatement* statement, bytes name, str value):
    cdef CassError error
    error = cass_statement_bind_string_by_name(statement, name, get_ascii(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_TEXT
cdef get_text(object value):
    if isinstance(value, str):
        return value.encode()
    elif isinstance(value, bytes):
        return value
    else:
        return str(value).encode()

cdef inline bind_string(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_string(statement, index, get_text(value))
    raise_if_error(error)

cdef inline bind_string_by_name(CassStatement* statement, bytes name, str value):
    cdef CassError error
    error = cass_statement_bind_string_by_name(statement, name, get_text(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_BLOB
cdef inline bind_bytes(CassStatement* statement, int index, bytes value):
    cdef CassError error
    error = cass_statement_bind_bytes(statement, index, <const cass_byte_t*>value, len(value))
    raise_if_error(error)

cdef inline bind_bytes_by_name(CassStatement* statement, bytes name, bytes value):
    cdef CassError error
    error = cass_statement_bind_bytes_by_name(statement, name, <const cass_byte_t*> value, len(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_UUID
cdef CassUuid get_cass_uuid(object value):
    from uuid import UUID
    cdef bytes bytes_value
    cdef CassUuid cass_uuid
    cdef CassError error
    if isinstance(value, UUID):
        bytes_value = str(value).encode()
    elif isinstance(value, str):
        bytes_value = str(UUID(value)).encode()
    else:
        raise ValueError(f'Bad value for UUID type: {value}')
    error = cass_uuid_from_string(bytes_value, &cass_uuid)
    raise_if_error(error)
    return cass_uuid

cdef inline bind_uuid(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_uuid(statement, index, get_cass_uuid(value))
    raise_if_error(error)

cdef inline bind_uuid_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_uuid_by_name(statement, name, get_cass_uuid(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_INET
cdef CassInet get_cass_inet(object value):
    from ipaddress import IPv4Address, IPv6Address
    cdef CassInet cass_inet
    cdef bytes bytes_value
    cdef CassError error

    if isinstance(value, (IPv4Address, IPv6Address)):
        bytes_value = str(value).encode()
    else:
        bytes_value = value.encode()
    error = cass_inet_from_string(<const char*>bytes_value, &cass_inet)
    raise_if_error(error)
    return cass_inet

cdef inline bind_inet(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_inet(statement, index, get_cass_inet(value))
    raise_if_error(error)

cdef inline bind_inet_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_inet_by_name(statement, name, get_cass_inet(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_DATE
cdef get_cass_date(object value):
    from datetime import date, datetime, timezone
    cdef CassError error
    cdef cass_uint32_t cass_date
    cdef cass_int64_t epoch_secs

    if isinstance(value, date):
        epoch_secs = int(datetime.fromtimestamp(
            int(value.strftime('%s')))
                         .replace(tzinfo=timezone.utc).timestamp())
    elif isinstance(value, datetime):
        epoch_secs = int(value.replace(tzinfo=timezone.utc).timestamp())
    elif isinstance(value, str):
        epoch_secs = int(datetime.strptime(value, "%Y-%m-%d")
                         .replace(tzinfo=timezone.utc).timestamp())
    else:
        epoch_secs = int(value)

    cass_date = cass_date_from_epoch(epoch_secs)
    return cass_date

cdef inline bind_date(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_uint32(statement, index, get_cass_date(value))
    raise_if_error(error)

cdef inline bind_date_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_uint32_by_name(statement, name, get_cass_date(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_TIME
cdef get_cass_time(object value):
    from datetime import datetime, timezone, time
    cdef CassError error
    cdef cass_int64_t time_of_day
    cdef cass_int64_t epoch_secs

    if isinstance(value, time):
        epoch_secs = int(datetime.now().replace(hour=value.hour,
                                                minute=value.minute,
                                                second=value.second,
                                                microsecond=value.microsecond,
                                                tzinfo=timezone.utc).timestamp())
    elif isinstance(value, datetime):
        epoch_secs = int(value.replace(tzinfo=timezone.utc).timestamp())
    elif isinstance(value, str):
        value = time.fromisoformat(value)
        epoch_secs = int(datetime.now().replace(hour=value.hour,
                                                minute=value.minute,
                                                second=value.second,
                                                microsecond=value.microsecond,
                                                tzinfo=timezone.utc).timestamp())
    else:
        epoch_secs = int(value)
    time_of_day = cass_time_from_epoch(epoch_secs)
    return time_of_day

cdef inline bind_time(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_int64(statement, index, get_cass_time(value))
    raise_if_error(error)

cdef inline bind_time_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_int64_by_name(statement, name, get_cass_time(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_TIMESTAMP
cdef get_cass_timestamp(object value):
    from datetime import datetime, timezone
    cdef CassError error
    cdef cass_int64_t timestamp

    if isinstance(value, datetime):
        timestamp = int(value.replace(tzinfo=timezone.utc).timestamp()*1000)
    elif isinstance(value, str):
        value = datetime.fromisoformat(value)
        timestamp = int(value.replace(hour=value.hour,
                                                minute=value.minute,
                                                second=value.second,
                                                microsecond=value.microsecond,
                                                tzinfo=timezone.utc).timestamp()*1000)
    else:
        timestamp = int(value*1000)
    return timestamp

cdef inline bind_timestamp(CassStatement* statement, int index, object value):
    cdef CassError error
    error = cass_statement_bind_int64(statement, index, get_cass_timestamp(value))
    raise_if_error(error)

cdef inline bind_timestamp_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    error = cass_statement_bind_int64_by_name(statement, name, get_cass_timestamp(value))
    raise_if_error(error)

# CASS_VALUE_TYPE_DURATION
cdef tuple get_cass_duration(object value):
    from datetime import timedelta
    cdef cass_int64_t NANOS_IN_A_SEC = 1000 * 1000 * 1000
    cdef cass_int64_t NANOS_IN_A_US = 1000
    cdef cass_int32_t month = 0
    cdef cass_int32_t day = 0
    cdef cass_int64_t nanos = 0

    if isinstance(value, timedelta):
        days = value.days
        nanos = value.seconds * NANOS_IN_A_SEC + value.microseconds * NANOS_IN_A_US
    else:
        raise NotImplementedError("Only instance of datetime.timedelta supported")
    return month, days, nanos

cdef inline bind_duration(CassStatement* statement, int index, object value):
    cdef CassError error
    month, days, nanos = get_cass_duration(value)
    error = cass_statement_bind_duration(statement, index, month, days, nanos)
    raise_if_error(error)

cdef inline bind_duration_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    month, days, nanos = get_cass_duration(value)
    error = cass_statement_bind_duration_by_name(statement, name, month, days, nanos)
    raise_if_error(error)

# Collections
cdef bind_collection_by_value_type(CassCollection* collection, object value, const CassDataType* cass_data_type, CassValueType cass_value_type):
    cdef CassCollection* nested_collection
    cdef CassError error

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise ValueError(f"Unknown type for collection value {value}")
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        cass_value = cass_true if value else cass_false
        error = cass_collection_append_bool(collection, cass_value)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_collection_append_int8(collection, get_int8(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_collection_append_int16(collection, get_int16(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_collection_append_int32(collection, get_int32(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_collection_append_int64(collection, get_int64(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_collection_append_float(collection, get_float(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_collection_append_double(collection, <cass_double_t>get_float(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_collection_append_string(collection, get_ascii(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_collection_append_string(collection, get_text(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_collection_append_bytes(collection, <const cass_byte_t*>value, len(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = get_cass_decimal(value)
        error = cass_collection_append_decimal(collection, <const cass_byte_t*> value, len(value), scale)
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_collection_append_uuid(collection, get_cass_uuid(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_collection_append_inet(collection, get_cass_inet(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = error = cass_collection_append_int64(collection, get_cass_timestamp(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_collection_append_uint32(collection, get_cass_date(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = error = cass_collection_append_int64(collection, get_cass_time(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = get_cass_duration(value)
        error = cass_collection_append_duration(collection, month, days, nanos)
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        nested_collection = get_collection(value, cass_data_type)
        if nested_collection == NULL:
            raise ValueError(f'Unable to bind collection with value {value}')
        error = cass_collection_append_collection(collection, nested_collection)
        cass_collection_free(nested_collection)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type)
        if cass_tuple == NULL:
            raise ValueError(f'Unable to bind tuple with value {value}')
        error = cass_collection_append_tuple(collection, cass_tuple)
        cass_tuple_free(cass_tuple)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        user_type = get_udt(value, cass_data_type)
        if user_type == NULL:
            raise ValueError(f'Unable to bind UDT with value {value}')
        error = cass_collection_append_user_type(collection, user_type)
        cass_user_type_free(user_type)
        raise_if_error(error)
    else:
        raise ValueError(f"Value {value} not supported")

cdef CassCollection* get_collection(object value, const CassDataType* cass_data_type):
    cdef CassCollection* collection = NULL
    cdef CassError error

    collection_type = cass_data_type_type(cass_data_type)
    collection = cass_collection_new_from_data_type(cass_data_type, len(value))

    sub_data_type = cass_data_type_sub_data_type(cass_data_type, 0)
    sub_value_type = cass_data_type_type(sub_data_type)

    if collection_type == CASS_VALUE_TYPE_MAP:
        if not isinstance(value, dict):
            raise ValueError('Value type "map" must be dict')
        for k, v in value.items():
            bind_collection_by_value_type(collection, k, sub_data_type, sub_value_type)
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, 1)
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_collection_by_value_type(collection, v, sub_data_type, sub_value_type)
    else:
        for i, el in enumerate(value):
            bind_collection_by_value_type(collection, el, sub_data_type, sub_value_type)

    # TODO: cass_collection_free(collection)
    return collection


# CASS_VALUE_TYPE_MAP, CASS_VALUE_TYPE_SET, CASS_VALUE_TYPE_LIST
cdef bind_collection(CassStatement* statement, int index, object value, const CassDataType* cass_data_type):
    cdef CassCollection* collection
    cdef CassError error
    collection = get_collection(value, cass_data_type)
    if collection == NULL:
        raise ValueError(f'Unable to bind collection with value {value}')
    error = cass_statement_bind_collection(statement, index, collection)
    cass_collection_free(collection)
    raise_if_error(error)

cdef inline bind_collection_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type):
    cdef CassCollection* collection
    cdef CassError error
    collection = get_collection(value, cass_data_type)
    if collection == NULL:
        raise ValueError(f'Unable to bind collection with value {value}')
    error = cass_statement_bind_collection_by_name(statement, name, collection)
    cass_collection_free(collection)
    raise_if_error(error)

# CASS_VALUE_TYPE_TUPLE
cdef inline bind_tuple_by_value_type(CassTuple* cass_tuple, size_t index, object value, const CassDataType* cass_data_type, CassValueType cass_value_type):
    cdef CassCollection* collection
    cdef CassError error

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise ValueError(f"Unknown type for tuple index {index}")
    elif value is None:
        error = cass_tuple_set_null(cass_tuple, index)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        cass_value = cass_true if value else cass_false
        error = cass_tuple_set_bool(cass_tuple, index, cass_value)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_tuple_set_int8(cass_tuple, index, get_int8(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_tuple_set_int16(cass_tuple, index, get_int16(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_tuple_set_int32(cass_tuple, index, get_int32(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_tuple_set_int64(cass_tuple, index, get_int64(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_tuple_set_float(cass_tuple, index, get_float(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_tuple_set_double(cass_tuple, index, <cass_double_t>get_float(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_tuple_set_string(cass_tuple, index, get_ascii(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_tuple_set_string(cass_tuple, index, get_text(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_tuple_set_bytes(cass_tuple, index, <const cass_byte_t*>value, len(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = get_cass_decimal(value)
        error = cass_tuple_set_decimal(cass_tuple, index, <const cass_byte_t*> value, len(value), scale)
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_tuple_set_uuid(cass_tuple, index, get_cass_uuid(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_tuple_set_inet(cass_tuple, index, get_cass_inet(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = error = cass_tuple_set_int64(cass_tuple, index, get_cass_timestamp(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_tuple_set_uint32(cass_tuple, index, get_cass_date(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = error = cass_tuple_set_int64(cass_tuple, index, get_cass_time(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = get_cass_duration(value)
        error = cass_tuple_set_duration(cass_tuple, index, month, days, nanos)
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        collection = get_collection(value, cass_data_type)
        if collection == NULL:
            raise ValueError(f'Unable to bind collection with value {value}')
        error = cass_tuple_set_collection(cass_tuple, index, collection)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        nested_tuple = get_tuple(value, cass_data_type)
        if nested_tuple == NULL:
            raise ValueError(f'Unable to bind tuple with value {value}')
        error = cass_tuple_set_tuple(cass_tuple, index, nested_tuple)
        cass_tuple_free(nested_tuple)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        user_type = get_udt(value, cass_data_type)
        if user_type == NULL:
            raise ValueError(f'Unable to bind UDT with value {value}')
        error = cass_tuple_set_user_type(cass_tuple, index, user_type)
        cass_user_type_free(user_type)
        raise_if_error(error)
    else:
        raise ValueError(f"Value {value} not supported")

cdef CassTuple* get_tuple(object value, const CassDataType* cass_data_type):
    cdef CassTuple * cass_tuple = NULL
    cdef CassError error
    cdef size_t type_count

    type_count = cass_data_type_sub_type_count(cass_data_type)
    if len(value) > type_count:
        raise ValueError(f'Wrong tuple size (must be {type_count}) for value {value}')

    cass_tuple = cass_tuple_new(len(value))

    for i, el in enumerate(value):
        sub_data_type = cass_data_type_sub_data_type(cass_data_type, <size_t>i)
        sub_value_type = cass_data_type_type(sub_data_type)
        bind_tuple_by_value_type(cass_tuple, i, el, sub_data_type, sub_value_type)
    return cass_tuple

cdef inline bind_tuple(CassStatement* statement, size_t index, object value, const CassDataType* cass_data_type):
    cdef CassError error
    cass_tuple = get_tuple(value, cass_data_type)
    if cass_tuple == NULL:
        raise ValueError(f'Unable to bind tuple with value {value}')
    error = cass_statement_bind_tuple(statement, index, cass_tuple)
    cass_tuple_free(cass_tuple)
    raise_if_error(error)

cdef inline bind_tuple_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type):
    cdef CassError error
    cass_tuple = get_tuple(value, cass_data_type)
    if cass_tuple == NULL:
        raise ValueError(f'Unable to bind tuple with value {value}')

    error = cass_statement_bind_tuple_by_name(statement, name, cass_tuple)
    cass_tuple_free(cass_tuple)
    raise_if_error(error)

# CASS_VALUE_TYPE_UDT
cdef bind_udt_by_value_type(CassUserType* user_type, bytes name, object value, const CassDataType* cass_data_type, CassValueType cass_value_type):
    cdef CassCollection* collection
    cdef CassError error

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise ValueError(f"Unknown type for column {name}")
    elif value is None:
        error = cass_user_type_set_null_by_name(user_type, name)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_user_type_set_bool_by_name(user_type, name, cass_true if value else cass_false)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_user_type_set_int8_by_name(user_type, name, get_int8(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_user_type_set_int16_by_name(user_type, name, get_int16(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_user_type_set_int32_by_name(user_type, name, get_int32(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_user_type_set_int64_by_name(user_type, name, get_int64(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_user_type_set_float_by_name(user_type, name, get_float(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_user_type_set_double_by_name(user_type, name, <cass_double_t>get_float(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = get_cass_decimal(value)
        error = cass_user_type_set_decimal_by_name(user_type, name, <const cass_byte_t*>value, len(value), scale)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_user_type_set_string_by_name(user_type, name, get_ascii(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_user_type_set_string_by_name(user_type, name, get_text(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_user_type_set_bytes_by_name(user_type, name, <const cass_byte_t*>value, len(value))
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_user_type_set_uuid_by_name(user_type, name, get_cass_uuid(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_user_type_set_inet_by_name(user_type, name, <CassInet>get_cass_inet(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_user_type_set_uint32_by_name(user_type, name, get_cass_date(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_user_type_set_int64_by_name(user_type, name, get_cass_time(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_user_type_set_int64_by_name(user_type, name, get_cass_timestamp(value))
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = get_cass_duration(value)
        error = cass_user_type_set_duration_by_name(user_type, name, month, days, nanos)
        raise_if_error(error)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        collection = get_collection(value, cass_data_type)
        if collection == NULL:
            raise ValueError(f'Unable to bind collection with value {value}')
        error = cass_user_type_set_collection_by_name(user_type, name, collection)
        cass_collection_free(collection)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type)
        if cass_tuple == NULL:
            raise ValueError(f'Unable to bind tuple with value {value}')
        error = cass_user_type_set_tuple_by_name(user_type, name, cass_tuple)
        cass_tuple_free(cass_tuple)
        raise_if_error(error)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        nested_user_type = get_udt(value, cass_data_type)
        if nested_user_type == NULL:
            raise ValueError(f'Unable to bind UDT with value {value}')
        error = cass_user_type_set_user_type_by_name(user_type, name, nested_user_type)
        cass_user_type_free(nested_user_type)
        raise_if_error(error)
    else:
        raise ValueError(f"Type {cass_value_type} not supported")

cdef CassUserType* get_udt(object value, const CassDataType* cass_data_type):
    cdef CassUserType* user_type = NULL
    user_type = cass_user_type_new_from_data_type(cass_data_type)

    for k, v in value.items():
        sub_data_type = cass_data_type_sub_data_type_by_name(cass_data_type, k.encode())
        sub_value_type = cass_data_type_type(sub_data_type)
        bind_udt_by_value_type(user_type, k.encode(), v, sub_data_type, sub_value_type)
    return user_type

cdef inline bind_udt(CassStatement* statement, size_t index, object value, const CassDataType* cass_data_type):
    cdef CassUserType * user_type
    cdef CassError error

    user_type = get_udt(value, cass_data_type)

    if user_type == NULL:
        raise ValueError(f'Unable to bind UDT with value {value}')

    error = cass_statement_bind_user_type(statement, index, user_type)
    cass_user_type_free(user_type)
    raise_if_error(error)


cdef inline bind_udt_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type):
    cdef CassUserType * user_type
    cdef CassError error

    user_type = get_udt(value, cass_data_type)

    if user_type == NULL:
        raise ValueError(f'Unable to bind UDT with value {value}')

    error = cass_statement_bind_user_type_by_name(statement, name, user_type)
    cass_user_type_free(user_type)
    raise_if_error(error)
