from cpython.dict cimport PyDict_SetItem
from cpython.list cimport PyList_GET_ITEM, PyList_New, PyList_SET_ITEM
from cpython.tuple cimport PyTuple_New, PyTuple_SET_ITEM
from cpython.ref cimport Py_INCREF


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

    def __iter__(self):
        return zip(self.keys(), self.values())

    def __len__(self):
        return self.result.column_count()

    def column_count(self):
        return self.result.column_count()

    def keys(self):
        return self.result.columns_names()

    def values(self):
        cdef size_t count
        cdef const CassValue* cass_value

        count = cass_result_column_count(self.result.cass_result)
        for index in range(count):
            cass_value = cass_row_get_column(self.cass_row, index)
            if cass_value == NULL:
                raise ColumnNotFound(f'ColumnNotFound with index {index}')
            yield get_cass_value(cass_value, self.result.native_types)

    def as_dict(self):
        cdef size_t count = cass_result_column_count(self.result.cass_result)
        cdef const CassValue* cass_value
        cdef size_t index
        cdef int8_t native_types = self.result.native_types
        cdef list names = self.result.columns_names()
        cdef dict result = {}
        for index in range(count):
            cass_value = cass_row_get_column(self.cass_row, index)
            if cass_value == NULL:
                raise ColumnNotFound(f'ColumnNotFound with index {index}')
            PyDict_SetItem(
                result,
                <object>PyList_GET_ITEM(names, index),
                get_cass_value(cass_value, native_types),
            )
        return result

    def as_list(self):
        cdef size_t count = cass_result_column_count(self.result.cass_result)
        cdef const CassValue* cass_value
        cdef size_t index
        cdef int8_t native_types = self.result.native_types
        cdef list result = PyList_New(count)
        cdef object value
        for index in range(count):
            cass_value = cass_row_get_column(self.cass_row, index)
            if cass_value == NULL:
                raise ColumnNotFound(f'ColumnNotFound with index {index}')
            value = get_cass_value(cass_value, native_types)
            Py_INCREF(value)
            PyList_SET_ITEM(result, index, value)
        return result

    def as_tuple(self):
        cdef size_t count = cass_result_column_count(self.result.cass_result)
        cdef const CassValue* cass_value
        cdef size_t index
        cdef int8_t native_types = self.result.native_types
        cdef tuple result = PyTuple_New(count)
        cdef object value
        for index in range(count):
            cass_value = cass_row_get_column(self.cass_row, index)
            if cass_value == NULL:
                raise ColumnNotFound(f'ColumnNotFound with index {index}')
            value = get_cass_value(cass_value, native_types)
            Py_INCREF(value)
            PyTuple_SET_ITEM(result, index, value)
        return result

    def as_named_tuple(self):
        cdef size_t count = cass_result_column_count(self.result.cass_result)
        cdef const CassValue* cass_value
        cdef size_t index
        cdef int8_t native_types = self.result.native_types
        cdef list names = self.result.columns_names()
        cdef tuple result = PyTuple_New(count)
        cdef tuple pair
        cdef object key, value
        for index in range(count):
            cass_value = cass_row_get_column(self.cass_row, index)
            if cass_value == NULL:
                raise ColumnNotFound(f'ColumnNotFound with index {index}')
            key = <object>PyList_GET_ITEM(names, index)
            value = get_cass_value(cass_value, native_types)
            pair = PyTuple_New(2)
            Py_INCREF(key)
            PyTuple_SET_ITEM(pair, 0, key)
            Py_INCREF(value)
            PyTuple_SET_ITEM(pair, 1, value)
            Py_INCREF(pair)
            PyTuple_SET_ITEM(result, index, pair)
        return result

    def column_value_by_index(self, size_t index):
        """ Returns the column value by `column index`.
        Raises an exception if the column can not be found"""
        cdef const CassValue* cass_value

        cass_value = cass_row_get_column(self.cass_row, index)
        if cass_value == NULL:
            raise ColumnNotFound(f'ColumnNotFound with index {index}')

        return get_cass_value(cass_value, self.result.native_types)

    def column_value(self, str column_name):
        """ Returns the column value called `column_name`.

        Raises an exception if the column can not be found"""

        cdef const CassValue* cass_value

        cass_value = cass_row_get_column_by_name(self.cass_row, column_name.encode())
        if cass_value == NULL:
            raise ColumnNotFound(column_name)

        return get_cass_value(cass_value, self.result.native_types)

    def __getitem__(self, name):
        if isinstance(name, int):
            return self.column_value_by_index(name)
        elif isinstance(name, slice):
            return self.as_tuple()[name]
        else:
            return self.column_value(name)

    def __getattr__(self, name):
        return self.column_value(name)
