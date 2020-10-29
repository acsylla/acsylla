cdef class Row:
    cdef:
        const CassRow* cass_row
        Result result

    @staticmethod
    cdef Row new_(const CassRow* cass_row, Result result)

    cdef int _int(self, const CassValue * cass_value)
    cdef TypeUUID _uuid(self, const CassValue * cass_value)
    cdef float _float(self, const CassValue * cass_value)
    cdef object _bool(self, const CassValue * cass_value)
    cdef str _string(self, const CassValue * cass_value)
    cdef bytes _bytes(self, const CassValue * cass_value)
