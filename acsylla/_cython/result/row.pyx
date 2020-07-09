cdef class Row:

    def __cinit__(self):
        self.cass_row = NULL

    @staticmethod
    cdef Row new_(const CassRow* cass_row):
        cdef Row row

        row = Row()
        row.cass_row = cass_row
        return row

    def column_by_name(self, bytes name):
        """ Returns the row column called `name`.

        Raises a `ColumnNotFound` exception if the column can not be found"""
        cdef const CassValue* cass_value

        cass_value = cass_row_get_column_by_name(self.cass_row, name)
        if (cass_value == NULL):
            raise ColumnNotFound()

        return Value.new_(cass_value)
