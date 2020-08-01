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

    def column_by_name(self, str name):
        """ Returns the row column called `name`.

        Raises a `ColumnNotFound` exception if the column can not be found"""
        cdef const CassValue* cass_value
        cdef bytes_name = name.encode()

        cass_value = cass_row_get_column_by_name(self.cass_row, bytes_name)
        if (cass_value == NULL):
            raise ColumnNotFound()

        return Value.new_(cass_value)
