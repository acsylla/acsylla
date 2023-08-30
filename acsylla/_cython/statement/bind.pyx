cdef extern from "utils.cpp":
    int days_from_civil(int y, unsigned m, unsigned d) nogil

from cpython.datetime cimport date
from cpython.datetime cimport datetime
from cpython.datetime cimport time
from cpython.datetime cimport timedelta
from libc.time cimport time_t

import_datetime()


import re

_duration_re = re.compile(r"(\d+)(y|Y|mo|MO|mO|Mo|w|W|d|D|h|H|s|S|ms|MS|mS|Ms|us|US|uS|Us|µs|µS|ns|NS|nS|Ns|m|M)")


cdef inline (cass_int32_t, cass_int32_t, cass_int64_t) _parse_duration_str(str s) except *:
    cdef cass_int32_t months = 0
    cdef cass_int32_t days = 0
    cdef cass_int64_t nanos = 0
    cdef list matched = _duration_re.findall(s)

    for value, key in matched:
        if key in ('y', 'Y'):
            months += int(value) * 12
        elif key in ('mo', 'MO'):
            months += int(value)
        elif key in ('w', 'W'):
            days += int(value) * 7
        elif key in ('d', 'D'):
            days += int(value)
        elif key in ('h', 'H'):
            nanos += int(value) * 60 * 60 * 1000 * 1000 * 1000
        elif key in ('m', 'M'):
            nanos += int(value) * 60 * 1000 * 1000 * 1000
        elif key in ('s', 'S'):
            nanos += int(value) * 1000 * 1000 * 1000
        elif key in ('ms', 'MS'):
            nanos += int(value) * 1000 * 1000
        elif key in ('us', 'µs', 'US'):
            nanos += int(value) * 1000
        elif key in ('ns', 'NS'):
            nanos += int(value)
    if not matched:
        raise ValueError(f'Unknown duration format for value: "{s}"')
    if s[0] == '-':
        return -months, -days, -nanos
    return months, days, nanos


cdef inline as_bytes(object value, str encoding='utf-8'):
    if isinstance(value, bytes):
        return value
    return value.encode(encoding) if isinstance(value, str) else str(value).encode(encoding)


cdef inline as_blob(object value):
    if isinstance(value, bytes):
        return value
    raise ValueError(f'Value "{value}" is not bytes.')


cdef inline cass_bool_t as_bool(object value) except *:
    if value in (True, False, 0, 1):
        return cass_true if value else cass_false
    raise ValueError(f'Value "{value}" is not boolean.')


cdef inline (cass_byte_t*, cass_int32_t) as_cass_decimal(object value) except *:
    value = str(value) if not isinstance(value, str) else value
    scale = value.split('.')
    if not scale[0].isdigit():
        raise ValueError(f'Bad value for decimal type: "{value}"')
    if len(scale) == 2:
        if not scale[1].isdigit():
            raise ValueError(f'Bad value for decimal type: "{value}"')
        scale = len(scale[1])
    else:
        scale = 0

    return value.encode(), scale


cdef inline CassUuid as_cass_uuid(object value) except *:
    cdef CassUuid cass_uuid
    cdef CassError error
    error = cass_uuid_from_string(as_bytes(value), &cass_uuid)
    if error:
        raise ValueError(f'Bad UUID value: "{value}"')
    return cass_uuid


cdef inline CassInet as_cass_inet(object value) except *:
    cdef CassInet cass_inet
    cdef CassError error
    error = cass_inet_from_string(as_bytes(value), &cass_inet)
    if error:
        raise ValueError(f'Bad IP address value: "{value}"')
    return cass_inet


cdef inline time_t _timegm(int year, unsigned month, unsigned day, unsigned hour, unsigned minute, unsigned second) except * nogil:
    cdef int days_since_epoch = days_from_civil(year, month, day)
    return 60 * (60 * (24L * days_since_epoch + hour) + minute) + second


cdef inline cass_uint32_t as_cass_date(object value) except *:
    cdef cass_uint32_t cass_date
    cdef time_t epoch_secs

    if isinstance(value, (str, date, datetime)):
        if isinstance(value, str):
            value = datetime.fromisoformat(value)
        epoch_secs = _timegm(value.year, value.month, value.day, 0, 0, 0)
    else:
        epoch_secs = value

    cass_date = cass_date_from_epoch(epoch_secs)
    return cass_date


cdef inline cass_int64_t as_cass_time(object value) except *:
    cdef CassError error
    cdef cass_int64_t time_of_day

    if isinstance(value, str):
        value = time.fromisoformat(value)
    if isinstance(value, (time, datetime)):
        time_of_day = (value.hour * 60 * 60 + value.minute * 60 + value.second) * 1_000_000_000
        if value.tzinfo:
            time_of_day -= value.utcoffset().total_seconds() * 1_000_000_000
        time_of_day += value.microsecond * 1_000
    else:
        time_of_day = value * 1_000_000_000

    return time_of_day


cdef inline cass_int64_t as_cass_timestamp(object value) except *:
    cdef double timestamp

    if isinstance(value, (str, datetime)):
        if isinstance(value, str):
            value = datetime.fromisoformat(value)

        timestamp = _timegm(value.year, value.month, value.day, value.hour, value.minute, value.second)
        if value.tzinfo is not None:
            timestamp -= value.utcoffset().total_seconds()
        timestamp += (value.microsecond * 0.000001)
    else:
        timestamp = value
    return <cass_int64_t>(timestamp * 1000)


cdef inline (cass_int32_t, cass_int32_t, cass_int64_t) as_cass_duration(object value) except *:
    cdef cass_int32_t months = 0
    cdef cass_int32_t days = 0
    cdef cass_int64_t nanos = 0

    if isinstance(value, tuple) and len(value) == 3:
        months, days, nanos = value
    elif isinstance(value, str):
        months, days, nanos = _parse_duration_str(value)
    elif isinstance(value, timedelta):
        days = value.days
        nanos = value.seconds * 1000 * 1000 * 1000 + value.microseconds * 1000
    else:
        raise ValueError(f'Unknown duration format for value: "{value}"')

    return months, days, nanos


# CASS_VALUE_TYPE_MAP, CASS_VALUE_TYPE_SET, CASS_VALUE_TYPE_LIST
cdef inline void bind_collection_by_value_type(CassCollection* collection, object value, const CassDataType* cass_data_type, CassValueType cass_value_type) except *:
    cdef CassError error = CASS_OK

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise_if_error(CASS_ERROR_LIB_INVALID_VALUE_TYPE, f'Unknown type for collection value "{value}"'.encode())
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_collection_append_bool(collection, as_bool(value))
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_collection_append_int8(collection, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_collection_append_int16(collection, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_collection_append_int32(collection, int(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_collection_append_int64(collection, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_collection_append_float(collection, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_collection_append_double(collection, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_collection_append_string(collection, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_collection_append_string(collection, as_bytes(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_collection_append_bytes(collection, as_blob(value), len(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = as_cass_decimal(value)
        error = cass_collection_append_decimal(collection, value, len(value), scale)
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_collection_append_uuid(collection, as_cass_uuid(value))
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_collection_append_inet(collection, as_cass_inet(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_collection_append_int64(collection, as_cass_timestamp(value))
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_collection_append_uint32(collection, as_cass_date(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_collection_append_int64(collection, as_cass_time(value))
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = as_cass_duration(value)
        error = cass_collection_append_duration(collection, month, days, nanos)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        nested_collection = get_collection(value, cass_data_type)
        error = cass_collection_append_collection(collection, nested_collection)
        cass_collection_free(nested_collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type)
        error = cass_collection_append_tuple(collection, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        user_type = get_udt(value, cass_data_type)
        error = cass_collection_append_user_type(collection, user_type)
        cass_user_type_free(user_type)

    if error:
        raise_if_error(error)


cdef inline CassCollection* get_collection(object value, const CassDataType* cass_data_type) except *:
    cdef CassCollection* collection = NULL
    cdef CassError error
    cdef const CassDataType* sub_data_type
    cdef CassValueType sub_value_type

    collection = cass_collection_new_from_data_type(cass_data_type, len(value))

    if collection == NULL:
        raise ValueError(f'Unable to bind collection with value {value}')

    collection_type = cass_data_type_type(cass_data_type)

    if collection_type == CASS_VALUE_TYPE_MAP:
        if isinstance(value, dict):
            value = value.items()
        for k, v in value:
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, 0)
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_collection_by_value_type(collection, k, sub_data_type, sub_value_type)
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, 1)
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_collection_by_value_type(collection, v, sub_data_type, sub_value_type)
    else:
        sub_data_type = cass_data_type_sub_data_type(cass_data_type, 0)
        sub_value_type = cass_data_type_type(sub_data_type)
        for i, v in enumerate(value):
            bind_collection_by_value_type(collection, v, sub_data_type, sub_value_type)

    return collection


cdef inline CassError bind_collection(CassStatement* statement, int index, object value, const CassDataType* cass_data_type) except *:
    cdef CassCollection* collection
    cdef CassError error
    collection = get_collection(value, cass_data_type)
    error = cass_statement_bind_collection(statement, index, collection)
    cass_collection_free(collection)
    return error

cdef inline  CassError bind_collection_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type) except *:
    cdef CassCollection* collection
    cdef CassError error
    collection = get_collection(value, cass_data_type)
    error = cass_statement_bind_collection_by_name(statement, name, collection)
    cass_collection_free(collection)
    return error

# CASS_VALUE_TYPE_TUPLE
cdef inline void bind_tuple_by_value_type(CassTuple* cass_tuple, size_t index, object value, const CassDataType* cass_data_type, CassValueType cass_value_type) except *:
    cdef CassError error = CASS_OK

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise_if_error(CASS_ERROR_LIB_INVALID_VALUE_TYPE, f'Unknown type for Tuple index {index} value "{value}"'.encode())
    elif value is None:
        error = cass_tuple_set_null(cass_tuple, index)
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_tuple_set_bool(cass_tuple, index, as_bool(value))
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_tuple_set_int8(cass_tuple, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_tuple_set_int16(cass_tuple, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_tuple_set_int32(cass_tuple, index, int(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_tuple_set_int64(cass_tuple, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_tuple_set_float(cass_tuple, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_tuple_set_double(cass_tuple, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_tuple_set_string(cass_tuple, index, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_tuple_set_string(cass_tuple, index, as_bytes(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_tuple_set_bytes(cass_tuple, index, as_blob(value), len(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = as_cass_decimal(value)
        error = cass_tuple_set_decimal(cass_tuple, index, value, len(value), scale)
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_tuple_set_uuid(cass_tuple, index, as_cass_uuid(value))
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_tuple_set_inet(cass_tuple, index, as_cass_inet(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_tuple_set_int64(cass_tuple, index, as_cass_timestamp(value))
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_tuple_set_uint32(cass_tuple, index, as_cass_date(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_tuple_set_int64(cass_tuple, index, as_cass_time(value))
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = as_cass_duration(value)
        error = cass_tuple_set_duration(cass_tuple, index, month, days, nanos)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        collection = get_collection(value, cass_data_type)
        error = cass_tuple_set_collection(cass_tuple, index, collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        nested_tuple = get_tuple(value, cass_data_type)
        error = cass_tuple_set_tuple(cass_tuple, index, nested_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        user_type = get_udt(value, cass_data_type)
        error = cass_tuple_set_user_type(cass_tuple, index, user_type)

    if error:
        raise_if_error(error)


cdef inline CassTuple* get_tuple(object value, const CassDataType* cass_data_type) except *:
    cdef CassTuple * cass_tuple = NULL
    cdef CassError error
    cdef size_t type_count
    cdef size_t tuple_len = len(value)

    type_count = cass_data_type_sub_type_count(cass_data_type)
    if tuple_len > type_count:
        raise ValueError(
            f'Wrong tuple size (must be {type_count}) for value {value}')

    cass_tuple = cass_tuple_new(tuple_len)

    for i, v in enumerate(value):
        sub_data_type = cass_data_type_sub_data_type(cass_data_type, i)
        if sub_data_type == NULL:
            raise_if_error(CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS, f'Unable to bind Tuple index {i}'.encode())
        sub_value_type = cass_data_type_type(sub_data_type)
        bind_tuple_by_value_type(cass_tuple, i, v, sub_data_type, sub_value_type)

    return cass_tuple


cdef inline bind_tuple(CassStatement* statement, size_t index, object value, const CassDataType* cass_data_type):
    cdef CassError error
    cass_tuple = get_tuple(value, cass_data_type)
    error = cass_statement_bind_tuple(statement, index, cass_tuple)
    cass_tuple_free(cass_tuple)
    return error

cdef inline bind_tuple_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type):
    cdef CassError error
    cass_tuple = get_tuple(value, cass_data_type)
    error = cass_statement_bind_tuple_by_name(statement, name, cass_tuple)
    cass_tuple_free(cass_tuple)
    return error

# CASS_VALUE_TYPE_UDT
cdef inline bind_udt_value_by_name(CassUserType* user_type, bytes name, object value, const CassDataType* cass_data_type, CassValueType cass_value_type):
    cdef CassError error = CASS_OK

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise_if_error(CASS_ERROR_LIB_INVALID_VALUE_TYPE, f'Unknown type for UDT column {name} value "{value}"'.encode())
    elif value is None:
        error = cass_user_type_set_null_by_name(user_type, name)
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_user_type_set_bool_by_name(user_type, name, as_bool(value))
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_user_type_set_int8_by_name(user_type, name, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_user_type_set_int16_by_name(user_type, name, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_user_type_set_int32_by_name(user_type, name, int(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_user_type_set_int64_by_name(user_type, name, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_user_type_set_float_by_name(user_type, name, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_user_type_set_double_by_name(user_type, name, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = as_cass_decimal(value)
        error = cass_user_type_set_decimal_by_name(user_type, name, value, len(value), scale)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_user_type_set_string_by_name(user_type, name, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_user_type_set_string_by_name(user_type, name, as_bytes(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_user_type_set_bytes_by_name(user_type, name, as_blob(value), len(value))
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_user_type_set_uuid_by_name(user_type, name, as_cass_uuid(value))
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_user_type_set_inet_by_name(user_type, name, as_cass_inet(value))
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_user_type_set_uint32_by_name(user_type, name, as_cass_date(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_user_type_set_int64_by_name(user_type, name, as_cass_time(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_user_type_set_int64_by_name(user_type, name, as_cass_timestamp(value))
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = as_cass_duration(value)
        error = cass_user_type_set_duration_by_name(user_type, name, month, days, nanos)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        collection = get_collection(value, cass_data_type)
        error = cass_user_type_set_collection_by_name(user_type, name, collection)
        cass_collection_free(collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type)
        error = cass_user_type_set_tuple_by_name(user_type, name, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        nested_user_type = get_udt(value, cass_data_type)
        error = cass_user_type_set_user_type_by_name(user_type, name, nested_user_type)
        cass_user_type_free(nested_user_type)

    if error:
        raise_if_error(error)


cdef inline bind_udt_value_by_index(CassUserType* user_type, size_t index, object value, const CassDataType* cass_data_type, CassValueType cass_value_type):
    cdef CassCollection* collection
    cdef CassError error = CASS_OK

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise_if_error(CASS_ERROR_LIB_INVALID_VALUE_TYPE, f'Unknown type for UDT column {index} value "{value}"'.encode())
    elif value is None:
        error = cass_user_type_set_null(user_type, index)
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_user_type_set_bool(user_type, index, as_bool(value))
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_user_type_set_int8(user_type, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_user_type_set_int16(user_type, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_user_type_set_int32(user_type, index, int(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_user_type_set_int64(user_type, index, value)
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_user_type_set_float(user_type, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_user_type_set_double(user_type, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = as_cass_decimal(value)
        error = cass_user_type_set_decimal(user_type, index, value, len(value), scale)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_user_type_set_string(user_type, index, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_user_type_set_string(user_type, index, as_bytes(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_user_type_set_bytes(user_type, index, as_blob(value), len(value))
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_user_type_set_uuid(user_type, index, as_cass_uuid(value))
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_user_type_set_inet(user_type, index, as_cass_inet(value))
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_user_type_set_uint32(user_type, index, as_cass_date(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_user_type_set_int64(user_type, index, as_cass_time(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_user_type_set_int64(user_type, index, as_cass_timestamp(value))
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = as_cass_duration(value)
        error = cass_user_type_set_duration(user_type, index, month, days, nanos)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        collection = get_collection(value, cass_data_type)
        if collection == NULL:
            raise ValueError(f'Unable to bind collection with value {value}')
        error = cass_user_type_set_collection(user_type, index, collection)
        cass_collection_free(collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type)
        if cass_tuple == NULL:
            raise ValueError(f'Unable to bind tuple with value "{value}"')
        error = cass_user_type_set_tuple(user_type, index, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        nested_user_type = get_udt(value, cass_data_type)
        error = cass_user_type_set_user_type(user_type, index, nested_user_type)
        cass_user_type_free(nested_user_type)

    if error:
        raise_if_error(error)


cdef inline CassUserType* get_udt(object value, const CassDataType* cass_data_type) except *:
    cdef CassUserType* user_type = NULL

    user_type = cass_user_type_new_from_data_type(cass_data_type)

    if user_type == NULL:
        raise ValueError(f'Unable to bind UDT with value {value}')

    if isinstance(value, dict):
        for k, v in value.items():
            sub_data_type = cass_data_type_sub_data_type_by_name(cass_data_type, k.encode())
            if sub_data_type == NULL:
                raise_if_error(CASS_ERROR_LIB_NAME_DOES_NOT_EXIST, f'Unable to bind UDT column "{k}" with value "{v}"'.encode())
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_udt_value_by_name(user_type, k.encode(), v, sub_data_type, sub_value_type)
    else:
        for i, v in enumerate(value):
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, i)
            if sub_data_type == NULL:
                raise_if_error(CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS, f'Unable to bind UDT value "{v}" with index {i}'.encode())
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_udt_value_by_index(user_type, i, v, sub_data_type, sub_value_type)

    return user_type


cdef inline CassError bind_udt(CassStatement* statement, size_t index, object value, const CassDataType* cass_data_type)  except *:
    cdef CassError error
    cdef CassUserType* user_type = NULL

    user_type = get_udt(value, cass_data_type)
    error = cass_statement_bind_user_type(statement, index, user_type)
    cass_user_type_free(user_type)
    return error


cdef inline CassError bind_udt_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type) except *:
    cdef CassError error
    cdef CassUserType* user_type = NULL

    user_type = get_udt(value, cass_data_type)
    error = cass_statement_bind_user_type_by_name(statement, name, user_type)
    cass_user_type_free(user_type)
    return error
