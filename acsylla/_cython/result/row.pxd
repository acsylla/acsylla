cdef class Row:
    cdef:
        const CassRow* cass_row
        Result result

    @staticmethod
    cdef Row new_(const CassRow* cass_row, Result result)

    cdef object _int8(self, const CassValue * cass_value)
    cdef object _int16(self, const CassValue * cass_value)
    cdef object _int32(self, const CassValue * cass_value)
    cdef object _int64(self, const CassValue * cass_value)
    cdef object _uuid(self, const CassValue * cass_value)
    cdef object _float(self, const CassValue * cass_value)
    cdef object _double(self, const CassValue * cass_value)
    cdef object _decimal(self, const CassValue * cass_value)
    cdef object _bool(self, const CassValue * cass_value)
    cdef object _string(self, const CassValue * cass_value)
    cdef object _bytes(self, const CassValue * cass_value)
    cdef object _inet(self, const CassValue * cass_value)
    cdef object _date(self, const CassValue * cass_value)
    cdef object _time(self, const CassValue * cass_value)
    cdef object _timestamp(self, const CassValue * cass_value)
    cdef object _duration(self, const CassValue * cass_value)
    cdef object _map(self, const CassValue * cass_value)
    cdef object _set(self, const CassValue * cass_value)
    cdef object _list(self, const CassValue * cass_value)
    cdef object _tuple(self, const CassValue * cass_value)
    cdef object _udt(self, const CassValue * cass_value)
    cdef object _get_cass_value(self, const CassValue * cass_value)
