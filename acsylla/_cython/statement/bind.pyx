from uuid import UUID

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
    if value is True:
        error = cass_statement_bind_bool(statement, index, cass_true)
    else:
        error = cass_statement_bind_bool(statement, index, cass_false)
    raise_if_error(error)

cdef inline bind_bool_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    if value is True:
        error = cass_statement_bind_bool_by_name(statement, name, cass_true)
    else:
        error = cass_statement_bind_bool_by_name(statement, name, cass_false)
    raise_if_error(error)

# CASS_VALUE_TYPE_TINY_INT
cdef inline bind_int8(CassStatement* statement, int index, cass_int8_t value):
    cdef CassError error
    error = cass_statement_bind_int8(statement, index, value)
    raise_if_error(error)

cdef inline bind_int8_by_name(CassStatement* statement, bytes name, cass_int8_t value):
    cdef CassError error
    error = cass_statement_bind_int8_by_name(statement, name, value)
    raise_if_error(error)

# CASS_VALUE_TYPE_SMALL_INT
cdef inline bind_int16(CassStatement* statement, int index, cass_int16_t value):
    cdef CassError error
    error = cass_statement_bind_int16(statement, index, value)
    raise_if_error(error)

cdef inline bind_int16_by_name(CassStatement* statement, bytes name, cass_int16_t value):
    cdef CassError error
    error = cass_statement_bind_int8_by_name(statement, name, value)
    raise_if_error(error)

# CASS_VALUE_TYPE_INT
cdef inline bind_int32(CassStatement* statement, int index, cass_int32_t value):
    cdef CassError error
    error = cass_statement_bind_int32(statement, index, value)
    raise_if_error(error)

cdef inline bind_int32_by_name(CassStatement* statement, bytes name, cass_int32_t value):
    cdef CassError error
    error = cass_statement_bind_int32_by_name(statement, name, value)
    raise_if_error(error)

# CASS_VALUE_TYPE_BIGINT
cdef inline bind_int64(CassStatement* statement, int index, cass_int64_t value):
    cdef CassError error
    error = cass_statement_bind_int64(statement, index, value)
    raise_if_error(error)

cdef inline bind_int64_by_name(CassStatement* statement, bytes name, cass_int64_t value):
    cdef CassError error
    error = cass_statement_bind_int64_by_name(statement, name, value)
    raise_if_error(error)

# CASS_VALUE_TYPE_FLOAT
cdef inline bind_float(CassStatement* statement, int index, float value):
    cdef CassError error
    error = cass_statement_bind_float(statement, index, value)
    raise_if_error(error)

cdef inline bind_float_by_name(CassStatement* statement, bytes name, float value):
    cdef CassError error
    error = cass_statement_bind_float_by_name(statement, name, value)
    raise_if_error(error)

# CASS_VALUE_TYPE_DECIMAL
cdef inline bind_decimal(CassStatement* statement, int index, object value):
    from decimal import Decimal
    cdef object t
    cdef cass_int32_t scale
    cdef CassError error
    if not isinstance(value, Decimal):
        value = Decimal(value)
    t = value.as_tuple()
    scale = len(t.digits[len(t.digits[:t.exponent]):])
    value = str(value).encode()
    error = cass_statement_bind_decimal(statement, index, <const cass_byte_t *> value, len(value), scale)
    raise_if_error(error)

cdef inline bind_decimal_by_name(CassStatement* statement, bytes name, object value):
    from decimal import Decimal
    cdef object t
    cdef cass_int32_t scale
    cdef CassError error
    if not isinstance(value, Decimal):
        value = Decimal(value)
    t = value.as_tuple()
    scale = len(t.digits[len(t.digits[:t.exponent]):])
    value = str(value).encode()
    error = cass_statement_bind_decimal_by_name(statement, name, <const cass_byte_t*> value, len(value), scale)
    raise_if_error(error)

# CASS_VALUE_TYPE_DOUBLE
cdef inline bind_double(CassStatement* statement, int index, double value):
    cdef CassError error
    error = cass_statement_bind_double(statement, index, value)
    raise_if_error(error)

cdef inline bind_double_by_name(CassStatement* statement, bytes name, double value):
    cdef CassError error
    error = cass_statement_bind_double_by_name(statement, name, value)
    raise_if_error(error)

# CASS_VALUE_TYPE_TEXT
cdef inline bind_string(CassStatement* statement, int index, str value):
    cdef CassError error
    cdef bytes bytes_value = value.encode()
    error = cass_statement_bind_string(statement, index, bytes_value)
    raise_if_error(error)

cdef inline bind_string_by_name(CassStatement* statement, bytes name, str value):
    cdef CassError error
    cdef bytes bytes_value
    bytes_value = value.encode()
    error = cass_statement_bind_string_by_name(statement, name, bytes_value)
    raise_if_error(error)

# CASS_VALUE_TYPE_BLOB
cdef inline bind_bytes(CassStatement* statement, int index, bytes value):
    cdef CassError error
    error = cass_statement_bind_bytes(statement, index, <const cass_byte_t*> value, len(value))
    raise_if_error(error)

cdef inline bind_bytes_by_name(CassStatement* statement, bytes name, bytes value):
    cdef CassError error
    error = cass_statement_bind_bytes_by_name(statement, name, <const cass_byte_t*> value, len(value))
    raise_if_error(error)

cdef inline bind_uuid(CassStatement* statement, int index, object value):
    cdef CassError error
    cdef CassUuid cass_uuid
    cdef bytes bytes_value
    if isinstance(value, TypeUUID):
        bytes_value = value.uuid.encode()
    elif isinstance(value, UUID):
        bytes_value = str(value).encode()
    elif isinstance(value, str):
        bytes_value = value.encode()
    else:
        bytes_value = value
    error = cass_uuid_from_string(bytes_value, &cass_uuid)
    raise_if_error(error)
    error = cass_statement_bind_uuid(statement, index, cass_uuid)
    raise_if_error(error)

cdef inline bind_uuid_by_name(CassStatement* statement, bytes name, object value):
    cdef CassError error
    cdef CassUuid cass_uuid
    cdef bytes bytes_value
    if isinstance(value, TypeUUID):
        bytes_value = value.uuid.encode()
    elif isinstance(value, UUID):
        bytes_value = str(value).encode()
    elif isinstance(value, str):
        bytes_value = value.encode()
    else:
        bytes_value = value
    error = cass_uuid_from_string(bytes_value, &cass_uuid)
    raise_if_error(error)
    error = cass_statement_bind_uuid_by_name(statement, name, cass_uuid)
    raise_if_error(error)

# CASS_VALUE_TYPE_INET
cdef inline bind_inet(CassStatement* statement, int index, object value):
    from ipaddress import IPv4Address, IPv6Address
    cdef CassError error
    cdef CassInet cass_inet
    cdef bytes bytes_value
    if isinstance(value, (IPv4Address, IPv6Address)):
        bytes_value = str(value).encode()
    else:
        bytes_value = value.encode()
    error = cass_inet_from_string(<const char*>bytes_value, &cass_inet)
    raise_if_error(error)
    error = cass_statement_bind_inet(statement, index, cass_inet)
    raise_if_error(error)

cdef inline bind_inet_by_name(CassStatement* statement, bytes name, object value):
    from ipaddress import IPv4Address, IPv6Address
    cdef CassError error
    cdef CassInet cass_inet
    cdef bytes bytes_value
    if isinstance(value, (IPv4Address, IPv6Address)):
        bytes_value = str(value).encode()
    else:
        bytes_value = value.encode()
    error = cass_inet_from_string(<const char*>bytes_value, &cass_inet)
    raise_if_error(error)
    error = cass_statement_bind_inet_by_name(statement, name, cass_inet)
    raise_if_error(error)

# CASS_VALUE_TYPE_DATE
cdef inline bind_date(CassStatement* statement, int index, object value):
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

    cass_date = cass_date_from_epoch(epoch_secs);

    error = cass_statement_bind_uint32(statement, index, cass_date)
    raise_if_error(error)

cdef inline bind_date_by_name(CassStatement* statement, bytes name, object value):
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

    cass_date = cass_date_from_epoch(epoch_secs);

    error = cass_statement_bind_uint32_by_name(statement, name, cass_date)
    raise_if_error(error)

# CASS_VALUE_TYPE_DATE
cdef inline bind_time(CassStatement* statement, int index, object value):
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

    time_of_day = cass_time_from_epoch(epoch_secs);
    error = cass_statement_bind_int64(statement, index, time_of_day)
    raise_if_error(error)

cdef inline bind_time_by_name(CassStatement* statement, bytes name, object value):
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

    time_of_day = cass_time_from_epoch(epoch_secs);
    error = cass_statement_bind_int64_by_name(statement, name, time_of_day)
    raise_if_error(error)

# CASS_VALUE_TYPE_TIMESTAMP
cdef inline bind_timestamp(CassStatement* statement, int index, object value):
    from datetime import datetime, timezone
    cdef CassError error
    cdef cass_int64_t timestamp

    if isinstance(value, datetime):
        timestamp = int(value.replace(tzinfo=timezone.utc).timestamp()*1000)
    elif isinstance(value, str):
        value = datetime.fromisoformat(value)
        timestamp = int(datetime.now().replace(hour=value.hour,
                                                minute=value.minute,
                                                second=value.second,
                                                microsecond=value.microsecond,
                                                tzinfo=timezone.utc).timestamp()*1000)
    else:
        timestamp = int(value*1000)

    error = cass_statement_bind_int64(statement, index, timestamp)
    raise_if_error(error)

cdef inline bind_timestamp_by_name(CassStatement* statement, bytes name, object value):
    from datetime import datetime, timezone
    cdef CassError error
    cdef cass_int64_t timestamp

    if isinstance(value, datetime):
        timestamp = int(value.replace(tzinfo=timezone.utc).timestamp()*1000)
    elif isinstance(value, str):
        value = datetime.fromisoformat(value)
        timestamp = int(datetime.now().replace(hour=value.hour,
                                                minute=value.minute,
                                                second=value.second,
                                                microsecond=value.microsecond,
                                                tzinfo=timezone.utc).timestamp()*1000)
    else:
        timestamp = int(value*1000)

    error = cass_statement_bind_int64_by_name(statement, name, timestamp)
    raise_if_error(error)

# CASS_VALUE_TYPE_DURATION
cdef inline bind_duration(CassStatement* statement, int index, object value):
    from datetime import timedelta
    cdef cass_int64_t NANOS_IN_A_SEC = 1000 * 1000 * 1000
    cdef cass_int64_t NANOS_IN_A_US = 1000
    cdef cass_int32_t month = 0
    cdef cass_int32_t day = 0
    cdef cass_int64_t nanos = 0
    cdef CassError error

    if isinstance(value, timedelta):
        days = value.days
        nanos = value.seconds * NANOS_IN_A_SEC + value.microseconds * NANOS_IN_A_US
    else:
        raise NotImplementedError("Only instance of datetime.timedelta supported")

    error = cass_statement_bind_duration(statement, index, month, days, nanos)
    raise_if_error(error)

cdef inline bind_duration_by_name(CassStatement* statement, bytes name, object value):
    from datetime import timedelta
    cdef cass_int64_t NANOS_IN_A_SEC = 1000 * 1000 * 1000
    cdef cass_int64_t NANOS_IN_A_US = 1000
    cdef cass_int32_t month = 0
    cdef cass_int32_t day = 0
    cdef cass_int64_t nanos = 0
    cdef CassError error

    if isinstance(value, timedelta):
        days = value.days
        nanos = value.seconds * NANOS_IN_A_SEC + value.microseconds * NANOS_IN_A_US
    else:
        raise NotImplementedError("Only instance of datetime.timedelta supported")

    error = cass_statement_bind_duration_by_name(statement, name, month, days, nanos)
    raise_if_error(error)

# CASS_VALUE_TYPE_MAP
cdef inline bind_map(CassStatement* statement, int index, object value):
    cdef CassCollection* collection = NULL
    cdef CassError error
    collection = cass_collection_new(CASS_COLLECTION_TYPE_MAP, len(value))
    for k, v in value.items():
        error = cass_collection_append_string(collection, <str>k.encode())
        raise_if_error(error)
        error = cass_collection_append_int64(collection, <cass_int64_t>v)
        raise_if_error(error)

    error = cass_statement_bind_collection(statement, index, collection)
    cass_collection_free(collection)
    raise_if_error(error)


cdef inline bind_map_by_name(CassStatement* statement, bytes name, object value):
    cdef CassCollection* collection = NULL
    cdef CassError error
    collection = cass_collection_new(CASS_COLLECTION_TYPE_MAP, len(value))
    for k, v in value.items():
        error = cass_collection_append_string(collection, <str>k.encode())
        raise_if_error(error)
        error = cass_collection_append_int64(collection, <cass_int64_t>v)
        raise_if_error(error)

    error = cass_statement_bind_collection_by_name(statement, name, collection)
    cass_collection_free(collection)
    raise_if_error(error)
