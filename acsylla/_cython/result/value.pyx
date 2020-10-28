from libc.stdlib cimport free


cdef class Value:

    def __cinit__(self):
        self.cass_value = NULL

    @staticmethod
    cdef Value new_(const CassValue* cass_value):
        cdef Value value

        value = Value()
        value.cass_value = cass_value
        return value

    def value(self):
        cdef CassValueType cass_type = cass_value_type(self.cass_value)

        if cass_type == CASS_VALUE_TYPE_UNKNOWN:
            raise RuntimeError("Value type returned can not be interpreted")
        elif cass_type == CASS_VALUE_TYPE_INT:
            return self._int()
        elif cass_type == CASS_VALUE_TYPE_UUID:
            return self._uuid()
        elif cass_type == CASS_VALUE_TYPE_FLOAT:
            return self._float()
        elif cass_type == CASS_VALUE_TYPE_BOOLEAN:
            return self._bool()
        elif cass_type == CASS_VALUE_TYPE_VARCHAR:
            return self._string()
        elif cass_type == CASS_VALUE_TYPE_BLOB:
            return self._bytes()
        else:
            raise ValueError("Type not supported")

    cdef int _int(self):
        """ Returns the int value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef int output
        cdef CassError error

        error = cass_value_get_int32(self.cass_value, <cass_int32_t*> &output)
        raise_if_error(error)

        return output

    cdef TypeUUID _uuid(self):
        cdef char output[CASS_UUID_STRING_LENGTH]
        cdef CassError error
        cdef CassUuid uuid

        error = cass_value_get_uuid(self.cass_value, &uuid)
        raise_if_error(error)

        cass_uuid_string(uuid, output)
        return TypeUUID(output.decode())

    cdef float _float(self):
        """ Returns the float value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef float output
        cdef CassError error

        error = cass_value_get_float(self.cass_value, <cass_float_t*> &output)
        raise_if_error(error)

        return output

    cdef object _bool(self):
        """ Returns the bool value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef cass_bool_t output
        cdef CassError error

        error = cass_value_get_bool(self.cass_value, <cass_bool_t*> &output)
        raise_if_error(error)

        if output == cass_true:
            return True
        else:
            return False

    cdef str _string(self):
        """ Returns the string value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef Py_ssize_t length = 0
        cdef char* output = NULL
        cdef CassError error
        cdef bytes string

        error = cass_value_get_string(self.cass_value,<const char**> &output, <size_t*> &length)
        raise_if_error(error)

        # This pointer does not need to be free up since its an
        # slice of the buffer kept by the Cassandra driver and related to
        # the result. When the result is free up all the space will be free up.
        string = output[:length]
        return string.decode()

    cdef bytes _bytes(self):
        """ Returns the bytes value of a column.

        Raises a derived `CassException` if the value can not be retrieved"""
        cdef Py_ssize_t length = 0
        cdef cass_byte_t* output = NULL
        cdef CassError error
        cdef bytes bytes_

        error = cass_value_get_bytes(self.cass_value, <const cass_byte_t**> &output, <size_t*> &length)
        raise_if_error(error)

        # This pointer does not need to be free up since its an
        # slice of the buffer kept by the Cassandra driver and related to
        # the result. When the result is free up all the space will be free up.
        bytes_ = output[:length]
        return bytes_
