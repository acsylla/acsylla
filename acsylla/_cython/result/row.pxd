cdef class Row:
    cdef:
        const CassRow* cass_row
        Result result

    @staticmethod
    cdef Row new_(const CassRow* cass_row, Result result)
