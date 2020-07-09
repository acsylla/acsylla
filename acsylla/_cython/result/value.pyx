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
        """ Returns the int value of a columnt.

        Raises a `ColumnValueError` if the value can not be retrieved"""
        cdef int output
        cdef CassError error

        error = cass_value_get_int32(self.cass_value, <cass_int32_t*> &output)
        if error != CASS_OK:
            raise ColumnValueError()

        return output
