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

    def column_value(self, str column_name):
        """ Returns the column value called `column_name`.

        Raises an exception if the column can not be found"""
        cdef CassValueType cass_type
        cdef const CassValue* cass_value
        cdef bytes_name = column_name.encode()

        cass_value = cass_row_get_column_by_name(self.cass_row, bytes_name)
        if (cass_value == NULL):
            raise ColumnNotFound(column_name)

        cass_type = cass_value_type(cass_value)

        if cass_type == CASS_VALUE_TYPE_UNKNOWN:
            raise RuntimeError("Value type returned can not be interpreted")
        elif cass_type == CASS_VALUE_TYPE_INT:
            return self._int(cass_value)
        elif cass_type == CASS_VALUE_TYPE_UUID:
            return self._uuid(cass_value)
        elif cass_type == CASS_VALUE_TYPE_FLOAT:
            return self._float(cass_value)
        elif cass_type == CASS_VALUE_TYPE_BOOLEAN:
            return self._bool(cass_value)
        elif cass_type == CASS_VALUE_TYPE_VARCHAR:
            return self._string(cass_value)
        elif cass_type == CASS_VALUE_TYPE_BLOB:
            return self._bytes(cass_value)
        else:
            raise ValueError("Type not supported")

    cdef int _int(self, const CassValue* cass_value):
        """ Returns the int value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef int output
        cdef CassError error

        error = cass_value_get_int32(cass_value, <cass_int32_t*> &output)
        raise_if_error(error)

        return output

    cdef TypeUUID _uuid(self, const CassValue* cass_value):
        cdef char output[CASS_UUID_STRING_LENGTH]
        cdef CassError error
        cdef CassUuid uuid

        error = cass_value_get_uuid(cass_value, &uuid)
        raise_if_error(error)

        cass_uuid_string(uuid, output)
        return TypeUUID(output.decode())

    cdef float _float(self, const CassValue* cass_value):
        """ Returns the float value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef float output
        cdef CassError error

        error = cass_value_get_float(cass_value, <cass_float_t*> &output)
        raise_if_error(error)

        return output

    cdef object _bool(self, const CassValue* cass_value):
        """ Returns the bool value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef cass_bool_t output
        cdef CassError error

        error = cass_value_get_bool(cass_value, <cass_bool_t*> &output)
        raise_if_error(error)

        if output == cass_true:
            return True
        else:
            return False

    cdef str _string(self, const CassValue* cass_value):
        """ Returns the string value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef Py_ssize_t length = 0
        cdef char* output = NULL
        cdef CassError error
        cdef bytes string

        error = cass_value_get_string(cass_value,<const char**> &output, <size_t*> &length)
        raise_if_error(error)

        # This pointer does not need to be free up since its an
        # slice of the buffer kept by the Cassandra driver and related to
        # the result. When the result is free up all the space will be free up.
        string = output[:length]
        return string.decode()

    cdef bytes _bytes(self, const CassValue* cass_value):
        """ Returns the bytes value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef Py_ssize_t length = 0
        cdef cass_byte_t* output = NULL
        cdef CassError error
        cdef bytes bytes_

        error = cass_value_get_bytes(cass_value, <const cass_byte_t**> &output, <size_t*> &length)
        raise_if_error(error)

        # This pointer does not need to be free up since its an
        # slice of the buffer kept by the Cassandra driver and related to
        # the result. When the result is free up all the space will be free up.
        bytes_ = output[:length]
        return bytes_
