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

    def int(self):
        """ Returns the int value of a column.

        Raises a `ColumnValueError` if the value can not be retrieved"""
        cdef int output
        cdef CassError error

        error = cass_value_get_int32(self.cass_value, <cass_int32_t*> &output)
        if error != CASS_OK:
            raise ColumnValueError()

        return output

    def float(self):
        """ Returns the float value of a column.

        Raises a `ColumnValueError` if the value can not be retrieved"""
        cdef float output
        cdef CassError error

        error = cass_value_get_float(self.cass_value, <cass_float_t*> &output)
        if error != CASS_OK:
            raise ColumnValueError()

        return output

    def bool(self):
        """ Returns the bool value of a column.

        Raises a `ColumnValueError` if the value can not be retrieved"""
        cdef cass_bool_t output
        cdef CassError error

        error = cass_value_get_bool(self.cass_value, <cass_bool_t*> &output)
        if error != CASS_OK:
            raise ColumnValueError()

        if output == cass_true:
            return True
        else:
            return False

    def string(self):
        """ Returns the string value of a column.

        Raises a `ColumnValueError` if the value can not be retrieved"""
        cdef Py_ssize_t length = 0
        cdef const char* output
        cdef CassError error
        cdef bytes string

        error = cass_value_get_string(self.cass_value, &output, <size_t*> &length)
        if error != CASS_OK:
            raise ColumnValueError()

        try:
            string = output[:length]
        except:
            free(<void*>output)

        return string.decode()
            
    def bytes(self):
        """ Returns the bytes value of a column.

        Raises a `ColumnValueError` if the value can not be retrieved"""
        cdef Py_ssize_t length = 0
        cdef const cass_byte_t* output
        cdef CassError error
        cdef bytes bytes_

        error = cass_value_get_bytes(self.cass_value, &output, <size_t*> &length)
        if error != CASS_OK:
            raise ColumnValueError()

        try:
            bytes_ = output[:length]
        except:
            free(<void*>output)
 
        return bytes_
