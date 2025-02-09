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
        result = []
        for index in range(count):
            cass_value = cass_row_get_column(self.cass_row, index)
            if cass_value == NULL:
                raise ColumnNotFound(f'ColumnNotFound with index {index}')
            yield get_cass_value(cass_value, self.result.native_types)

    def as_dict(self):
        return dict(self)

    def as_list(self):
        return list(self.values())

    def as_tuple(self):
        return tuple(self.values())

    def as_named_tuple(self):
        return tuple(zip(self.keys(), self.values()))

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
        if name in self.result.columns():
            return self.column_value(name)
