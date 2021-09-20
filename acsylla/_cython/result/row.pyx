cdef class Row:

    def __cinit__(self):
        self.cass_row = NULL

    @staticmethod
    cdef Row new_(const CassRow* cass_row, Result result):
        cdef Row row

        row = Row()
        row.cass_row = cass_row

        # Increase the references to the result object, behind the scenes
        # Cassandra uses the data owned by the result object, so we need to
        # keep the object alive while the row is still in use.
        row.result = result

        return row

    def column_count(self):
        return self.result.column_count()

    def as_dict(self):
        cdef Py_ssize_t length = 0
        cdef char* name = NULL
        cdef CassError error
        ret = {}
        for i in range(self.result.column_count()):
            error = cass_result_column_name(self.result.cass_result, i, <const char**> &name, <size_t*> &length)
            raise_if_error(error)
            ret[name.decode()] = self.column_value(name.decode())
        return ret

    def column_value(self, str column_name):
        """ Returns the column value called `column_name`.

        Raises an exception if the column can not be found"""
        cdef CassValueType cass_type
        cdef const CassValue* cass_value
        cdef bytes_name = column_name.encode()

        cass_value = cass_row_get_column_by_name(self.cass_row, bytes_name)
        if cass_value == NULL:
            raise ColumnNotFound(column_name)

        return self._get_cass_value(cass_value)

    cdef object _get_cass_value(self, const CassValue* cass_value):
        cdef CassValueType cass_type

        cdef cass_bool_t value_is_null = cass_value_is_null(cass_value)
        if value_is_null:
            return None

        cass_type = cass_value_type(cass_value)

        if cass_type == CASS_VALUE_TYPE_UNKNOWN:
            raise RuntimeError("Value type returned can not be interpreted")
        elif cass_type == CASS_VALUE_TYPE_TINY_INT:
            return self._int8(cass_value)
        elif cass_type == CASS_VALUE_TYPE_SMALL_INT:
            return self._int16(cass_value)
        elif cass_type == CASS_VALUE_TYPE_INT:
            return self._int32(cass_value)
        elif cass_type in (CASS_VALUE_TYPE_BIGINT, CASS_VALUE_TYPE_COUNTER):
            return self._int64(cass_value)
        elif cass_type in (CASS_VALUE_TYPE_UUID, CASS_VALUE_TYPE_TIMEUUID):
            return self._uuid(cass_value)
        elif cass_type == CASS_VALUE_TYPE_FLOAT:
            return self._float(cass_value)
        elif cass_type == CASS_VALUE_TYPE_DOUBLE:
            return self._double(cass_value)
        elif cass_type == CASS_VALUE_TYPE_DECIMAL:
            return self._decimal(cass_value)
        elif cass_type == CASS_VALUE_TYPE_BOOLEAN:
            return self._bool(cass_value)
        elif cass_type in (CASS_VALUE_TYPE_ASCII,
                           CASS_VALUE_TYPE_TEXT,
                           CASS_VALUE_TYPE_VARCHAR):
            return self._string(cass_value)
        elif cass_type in (CASS_VALUE_TYPE_BLOB,
                           CASS_VALUE_TYPE_VARINT,
                           CASS_VALUE_TYPE_CUSTOM):
            return self._bytes(cass_value)
        elif cass_type == CASS_VALUE_TYPE_INET:
            return self._inet(cass_value)
        elif cass_type == CASS_VALUE_TYPE_DATE:
            return self._date(cass_value)
        elif cass_type == CASS_VALUE_TYPE_TIME:
            return self._time(cass_value)
        elif cass_type == CASS_VALUE_TYPE_TIMESTAMP:
            return self._timestamp(cass_value)
        elif cass_type == CASS_VALUE_TYPE_DURATION:
            return self._duration(cass_value)
        elif cass_type == CASS_VALUE_TYPE_MAP:
            return self._map(cass_value)
        elif cass_type == CASS_VALUE_TYPE_SET:
            return self._set(cass_value)
        elif cass_type == CASS_VALUE_TYPE_LIST:
            return self._list(cass_value)
        elif cass_type == CASS_VALUE_TYPE_TUPLE:
            return self._tuple(cass_value)
        elif cass_type == CASS_VALUE_TYPE_UDT:
            return self._udt(cass_value)
        else:
            raise ValueError(f"Type not supported {cass_type}")

    cdef object _int8(self, const CassValue* cass_value):
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

    cdef object _int16(self, const CassValue* cass_value):
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

    cdef object _int32(self, const CassValue* cass_value):
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

    cdef object _int64(self, const CassValue* cass_value):
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

    cdef object _uuid(self, const CassValue* cass_value):
        from uuid import UUID
        cdef char output[CASS_UUID_STRING_LENGTH]
        cdef CassError error
        cdef CassUuid uuid

        error = cass_value_get_uuid(cass_value, &uuid)
        if error == CASS_ERROR_LIB_NULL_VALUE:
            return None
        else:
            raise_if_error(error)

        cass_uuid_string(uuid, output)
        return UUID(str(output.decode()))

    cdef object _float(self, const CassValue* cass_value):
        """ Returns the float value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef float output
        cdef CassError error

        error = cass_value_get_float(cass_value, <cass_float_t*> &output)
        if error == CASS_ERROR_LIB_NULL_VALUE:
            return None
        else:
            raise_if_error(error)

        return output

    cdef object _double(self, const CassValue* cass_value):
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

    cdef object _decimal(self, const CassValue* cass_value):
        """ Returns the decimal value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        from decimal import Decimal
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
        return Decimal(decimal_.decode())

    cdef object _bool(self, const CassValue* cass_value):
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

    cdef object _string(self, const CassValue* cass_value):
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

    cdef object _bytes(self, const CassValue* cass_value):
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

    cdef object _inet(self, const CassValue* cass_value):
        """ Returns the inet value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        from ipaddress import ip_address
        cdef CassInet output
        cdef char address[CASS_INET_STRING_LENGTH]
        cdef CassError error
        error = cass_value_get_inet(cass_value, <CassInet*>&output)
        if error == CASS_ERROR_LIB_NULL_VALUE:
            return None
        else:
            raise_if_error(error)
        cass_inet_string(output, <char*>&address)
        return ip_address(address.decode())

    cdef object _date(self, const CassValue* cass_value):
        from datetime import datetime
        cdef cass_uint32_t output
        cdef CassError error
        error = cass_value_get_uint32(cass_value, <cass_uint32_t *> &output)
        if error == CASS_ERROR_LIB_NULL_VALUE:
            return None
        else:
            raise_if_error(error)
        return datetime.utcfromtimestamp(cass_date_time_to_epoch(output, 0)).date()

    cdef object _time(self, const CassValue* cass_value):
        from datetime import datetime
        cdef cass_int64_t output
        cdef cass_int64_t epoch_secs
        cdef cass_uint32_t year_month_day
        cdef CassError error

        error = cass_value_get_int64(cass_value, <cass_int64_t *> &output)
        if error == CASS_ERROR_LIB_NULL_VALUE:
            return None
        else:
            raise_if_error(error)
        year_month_day = cass_date_from_epoch(0)
        epoch_secs = cass_date_time_to_epoch(year_month_day, output)
        return datetime.utcfromtimestamp(epoch_secs).time()

    cdef object _timestamp(self, const CassValue* cass_value):
        from datetime import datetime
        cdef cass_int64_t output
        cdef double epoch_secs
        cdef CassError error

        error = cass_value_get_int64(cass_value, <cass_int64_t *> &output)
        if error == CASS_ERROR_LIB_NULL_VALUE:
            return None
        else:
            raise_if_error(error)
        epoch_secs = <double>output / 1000.0
        return datetime.utcfromtimestamp(epoch_secs)

    cdef object _duration(self, const CassValue* cass_value):
        from datetime import timedelta
        cdef cass_int32_t months
        cdef cass_int32_t days
        cdef cass_int64_t nanos
        cdef CassError error

        error = cass_value_get_duration(cass_value, <cass_int32_t*>&months, <cass_int32_t*>&days, <cass_int64_t *>&nanos)
        if error == CASS_ERROR_LIB_NULL_VALUE:
            return None
        else:
            raise_if_error(error)
        if nanos:
            nanos = int(nanos / 1000)
        return timedelta(days=days, microseconds=nanos)

    cdef object _map(self, const CassValue* cass_value):
        cdef const CassValue* key
        cdef const CassValue* value
        cdef CassIterator* iterator = cass_iterator_from_map(cass_value);
        data = {}
        if iterator == NULL:
            return None
        while cass_iterator_next(iterator) == cass_true:
            key = cass_iterator_get_map_key(iterator)
            value = cass_iterator_get_map_value(iterator)
            data[self._get_cass_value(key)] = self._get_cass_value(value)
        cass_iterator_free(iterator)
        return data

    cdef object _set(self, const CassValue* cass_value):
        cdef const CassValue* value
        cdef CassIterator* iterator = cass_iterator_from_collection(cass_value);
        data = set()
        if iterator == NULL:
            return None
        while cass_iterator_next(iterator) == cass_true:
            value = cass_iterator_get_value(iterator)
            data.add(self._get_cass_value(value))
        cass_iterator_free(iterator)
        return data

    cdef object _list(self, const CassValue* cass_value):
        cdef const CassValue* value
        cdef CassIterator* iterator = cass_iterator_from_collection(cass_value);
        data = list()
        if iterator == NULL:
            return None
        while cass_iterator_next(iterator) == cass_true:
            value = cass_iterator_get_value(iterator)
            data.append(self._get_cass_value(value))
        cass_iterator_free(iterator)
        return data

    cdef object _tuple(self, const CassValue* cass_value):
        cdef const CassValue* value
        cdef CassIterator* iterator = cass_iterator_from_tuple(cass_value);
        data = list()
        if iterator == NULL:
            return None
        while cass_iterator_next(iterator) == cass_true:
            value = cass_iterator_get_value(iterator)
            data.append(self._get_cass_value(value))
        cass_iterator_free(iterator)
        return tuple(data)

    cdef object _udt(self, const CassValue* cass_value):
        cdef const char* field_name
        cdef size_t field_name_length
        cdef const CassValue* field_value
        cdef CassIterator* iterator = cass_iterator_fields_from_user_type(cass_value);
        data = {}
        while cass_iterator_next(iterator) == cass_true:
            cass_iterator_get_user_type_field_name(iterator, &field_name, &field_name_length)
            field_value = cass_iterator_get_user_type_field_value(iterator)
            data[field_name.decode()] = self._get_cass_value(field_value)
        cass_iterator_free(iterator)
        return data
