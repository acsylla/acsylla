cdef class Result:

    def __cinit__(self):
        self.cass_result = NULL

    def __dealloc__(self):
        cass_result_free(self.cass_result)

    @staticmethod
    cdef Result new_(const CassResult* cass_result):
        cdef Result result

        result = Result()
        result.cass_result = cass_result
        return result

    def count(self):
        """ Returns the total rows of the result"""
        cdef size_t count

        count = cass_result_row_count(self.cass_result)
        return count

    def column_count(self):
        """ Returns the total columns returned"""
        cdef size_t count

        count = cass_result_column_count(self.cass_result)
        return count

    def first(self):
        """ Return the first result, if there is no row
        returns None.
        """
        cdef const CassRow* cass_row

        cass_row = cass_result_first_row(self.cass_result)
        if (cass_row == NULL):
            return None

        return Row.new_(cass_row)
