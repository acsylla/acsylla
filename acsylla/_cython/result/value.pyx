from cpython.datetime cimport datetime
from cpython.datetime cimport time

from decimal import Decimal


cdef inline object get_cass_value(const CassValue* cass_value, int8_t native_types):
    cdef CassValueType cass_type

    cdef cass_bool_t value_is_null = cass_value_is_null(cass_value)
    if value_is_null:
        return None

    cass_type = cass_value_type(cass_value)

    if cass_type == CASS_VALUE_TYPE_UNKNOWN:
        raise RuntimeError("Value type returned can not be interpreted")
    elif cass_type == CASS_VALUE_TYPE_TINY_INT:
        return _int8(cass_value)
    elif cass_type == CASS_VALUE_TYPE_SMALL_INT:
        return _int16(cass_value)
    elif cass_type == CASS_VALUE_TYPE_INT:
        return _int32(cass_value)
    elif cass_type in (CASS_VALUE_TYPE_BIGINT, CASS_VALUE_TYPE_COUNTER):
        return _int64(cass_value)
    elif cass_type in (CASS_VALUE_TYPE_UUID, CASS_VALUE_TYPE_TIMEUUID):
        return _uuid(cass_value)
    elif cass_type == CASS_VALUE_TYPE_FLOAT:
        return _float(cass_value)
    elif cass_type == CASS_VALUE_TYPE_DOUBLE:
        return _double(cass_value)
    elif cass_type == CASS_VALUE_TYPE_DECIMAL:
        return _decimal(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_BOOLEAN:
        return _bool(cass_value)
    elif cass_type in (CASS_VALUE_TYPE_ASCII,
                       CASS_VALUE_TYPE_TEXT,
                       CASS_VALUE_TYPE_VARCHAR):
        return _string(cass_value)
    elif cass_type in (CASS_VALUE_TYPE_BLOB,
                       CASS_VALUE_TYPE_VARINT,
                       CASS_VALUE_TYPE_CUSTOM):
        return _bytes(cass_value)
    elif cass_type == CASS_VALUE_TYPE_INET:
        return _inet(cass_value)
    elif cass_type == CASS_VALUE_TYPE_DATE:
        return _date(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_TIME:
        return _time(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_TIMESTAMP:
        return _timestamp(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_DURATION:
        return _duration(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_MAP:
        return _map(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_SET:
        return _set(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_LIST:
        return _list(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_TUPLE:
        return _tuple(cass_value, native_types)
    elif cass_type == CASS_VALUE_TYPE_UDT:
        return _udt(cass_value, native_types)
    else:
        raise ValueError(f"Type not supported {cass_type}")

cdef inline object _int8(const CassValue* cass_value):
    """ Returns the int value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int8_t output
    cdef CassError error
    error = cass_value_get_int8(cass_value, <cass_int8_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    return output

cdef inline object _int16(const CassValue* cass_value):
    """ Returns the int value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int16_t output
    cdef CassError error
    error = cass_value_get_int16(cass_value, <cass_int16_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    return output

cdef inline object _int32(const CassValue* cass_value):
    """ Returns the int value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int32_t output
    cdef CassError error
    error = cass_value_get_int32(cass_value, <cass_int32_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    return output


cdef inline object _int64(const CassValue* cass_value):
    """ Returns the int value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int64_t output
    cdef CassError error
    error = cass_value_get_int64(cass_value, <cass_int64_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    return output


cdef inline object _uuid(const CassValue* cass_value):
    cdef char output[CASS_UUID_STRING_LENGTH]
    cdef CassError error
    cdef CassUuid uuid

    error = cass_value_get_uuid(cass_value, &uuid)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    cass_uuid_string(uuid, output)
    return output.decode()


cdef inline object _float(const CassValue* cass_value):
    """ Returns the float value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_float_t output
    cdef CassError error

    error = cass_value_get_float(cass_value, &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    return output


cdef inline object _double(const CassValue* cass_value):
    """ Returns the double value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef double output
    cdef CassError error

    error = cass_value_get_double(cass_value, <cass_double_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    return output


cdef inline object _decimal(const CassValue* cass_value, int8_t native_types):
    """ Returns the decimal value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef Py_ssize_t varint_size = 0
    cdef cass_byte_t* varint = NULL
    cdef cass_int32_t scale
    cdef CassError error
    cdef bytes decimal_

    error = cass_value_get_decimal(cass_value, <const cass_byte_t**> &varint, <size_t*> &varint_size, &scale)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    # This pointer does not need to be free up since its an
    # slice of the buffer kept by the Cassandra driver and related to
    # the result. When the result is free up all the space will be free up.
    decimal_ = varint[:varint_size]
    if native_types:
        return decimal_.decode()
    return Decimal(decimal_.decode())


cdef inline object _bool(const CassValue* cass_value):
    """ Returns the bool value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_bool_t output
    cdef CassError error

    error = cass_value_get_bool(cass_value, <cass_bool_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    if output == cass_true:
        return True
    else:
        return False

cdef inline object _string(const CassValue* cass_value):
    """ Returns the string value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef Py_ssize_t length = 0
    cdef char* output = NULL
    cdef CassError error
    cdef bytes string

    error = cass_value_get_string(cass_value,<const char**> &output, <size_t*> &length)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    # This pointer does not need to be free up since its an
    # slice of the buffer kept by the Cassandra driver and related to
    # the result. When the result is free up all the space will be free up.
    string = output[:length]
    return string.decode()

cdef inline object _bytes(const CassValue* cass_value):
    """ Returns the bytes value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef Py_ssize_t length = 0
    cdef cass_byte_t* output = NULL
    cdef CassError error
    cdef bytes bytes_

    error = cass_value_get_bytes(cass_value, <const cass_byte_t**> &output, <size_t*> &length)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    # This pointer does not need to be free up since its an
    # slice of the buffer kept by the Cassandra driver and related to
    # the result. When the result is free up all the space will be free up.
    bytes_ = output[:length]
    return bytes_

cdef inline object _inet(const CassValue* cass_value):
    """ Returns the inet value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef CassInet output
    cdef char address[CASS_INET_STRING_LENGTH]
    cdef CassError error
    error = cass_value_get_inet(cass_value, <CassInet*>&output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    cass_inet_string(output, <char*>&address)
    return address.decode()

cdef inline object _date(const CassValue* cass_value, int8_t native_types):
    cdef cass_uint32_t output
    cdef CassError error
    error = cass_value_get_uint32(cass_value, <cass_uint32_t *> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    if native_types:
        return cass_date_time_to_epoch(output, 0)
    return datetime.utcfromtimestamp(cass_date_time_to_epoch(output, 0)).date()

cdef inline object _time(const CassValue* cass_value, int8_t native_types):
    cdef cass_int64_t nanos
    cdef CassError error

    error = cass_value_get_int64(cass_value, <cass_int64_t *> &nanos)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    if native_types:
        return nanos / 1_000_000_000
    second, nanosecond = divmod(nanos, 1_000_000_000)
    minute, second = divmod(second, 60)
    hour = int(minute/60)
    return time(hour=hour, minute=minute-hour*60, second=second, microsecond=int(nanosecond/1_000))

cdef inline object _timestamp(const CassValue* cass_value, int8_t native_types):
    cdef cass_int64_t output
    cdef CassError error

    error = cass_value_get_int64(cass_value, <cass_int64_t *> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    if native_types:
        return output / 1000.0
    return datetime.utcfromtimestamp(output / 1000.0)


cdef inline object _duration(const CassValue* cass_value, int8_t native_types):
    cdef cass_int32_t months
    cdef cass_int32_t days
    cdef cass_int64_t nanos
    cdef CassError error

    error = cass_value_get_duration(cass_value, <cass_int32_t*>&months, <cass_int32_t*>&days, <cass_int64_t *>&nanos)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    if native_types:
        return months, days, nanos

    out = ''
    if months < 0:
        months = -months
        out = '-'
    y, mo = divmod(months, 12)
    if y != 0: out+= f'{y}y'
    if mo != 0: out+= f'{mo}mo'
    if days < 0:
        if not out: out = '-'
        days = -days
    if days != 0: out += f'{days}d'
    if nanos < 0:
        if not out: out = '-'
        nanos = -nanos
    if nanos != 0:
        s, n = divmod(nanos, 1_000_000_000)
        h, m = divmod(s, 3600)
        m, s = divmod(m, 60)
        if h !=0: out += f'{h}h'
        if m !=0: out += f'{m}m'
        if s !=0: out += f'{s}s'
        ms, us = divmod(n, 1_000_000)
        us, ns = divmod(us, 1_000)
        if ms !=0: out += f'{ms}ms'
        if us !=0: out += f'{us}us'
        if ns !=0: out += f'{ns}ns'

    return out


cdef inline object _map(const CassValue* cass_value, int8_t native_types):
    cdef const CassValue* key
    cdef const CassValue* value
    cdef CassIterator* iterator = cass_iterator_from_map(cass_value);
    data = {}
    if iterator == NULL:
        return None
    while cass_iterator_next(iterator) == cass_true:
        key = cass_iterator_get_map_key(iterator)
        value = cass_iterator_get_map_value(iterator)
        data[get_cass_value(key, native_types)] = get_cass_value(value, native_types)
    cass_iterator_free(iterator)
    return data


cdef inline object _set(const CassValue* cass_value, int8_t native_types):
    cdef const CassValue* value
    cdef CassIterator* iterator = cass_iterator_from_collection(cass_value);
    data = set()
    if iterator == NULL:
        return None
    while cass_iterator_next(iterator) == cass_true:
        value = cass_iterator_get_value(iterator)
        data.add(get_cass_value(value, native_types))
    cass_iterator_free(iterator)
    return data


cdef inline object _list(const CassValue* cass_value, int8_t native_types):
    cdef const CassValue* value
    cdef CassIterator* iterator = cass_iterator_from_collection(cass_value);
    data = list()
    if iterator == NULL:
        return None

    while cass_iterator_next(iterator) == cass_true:
        value = cass_iterator_get_value(iterator)
        data.append(get_cass_value(value, native_types))
    cass_iterator_free(iterator)
    return data


cdef inline object _tuple(const CassValue* cass_value, int8_t native_types):
    cdef const CassValue* value
    cdef CassIterator* iterator = cass_iterator_from_tuple(cass_value);
    data = list()
    if iterator == NULL:
        return None
    while cass_iterator_next(iterator) == cass_true:
        value = cass_iterator_get_value(iterator)
        data.append(get_cass_value(value, native_types))
    cass_iterator_free(iterator)
    return tuple(data)


cdef inline object _udt(const CassValue* cass_value, int8_t native_types):
    cdef const char* field_name
    cdef size_t field_name_length
    cdef const CassValue* field_value
    cdef CassIterator* iterator = cass_iterator_fields_from_user_type(cass_value);
    data = {}
    while cass_iterator_next(iterator) == cass_true:
        cass_iterator_get_user_type_field_name(iterator, &field_name, &field_name_length)
        field_value = cass_iterator_get_user_type_field_value(iterator)
        data[field_name[:field_name_length].decode()] = get_cass_value(field_value, native_types)
    cass_iterator_free(iterator)
    return data
