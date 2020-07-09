cdef class Row:
    cdef:
        const CassRow* cass_row

    @staticmethod
    cdef Row new_(const CassRow* cass_row)
