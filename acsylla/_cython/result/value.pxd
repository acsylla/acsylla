# The flags of a result for its values
cdef enum:
    # The str() of decimal, date, time and timestamp values, the tuple of duration ones
    NATIVE_TYPES = 1
    # The types of acsylla 1.x, a session with legacy_types=True
    LEGACY_TYPES = 2

cdef object _int8(const CassValue * cass_value)
cdef object _int16(const CassValue * cass_value)
cdef object _int32(const CassValue * cass_value)
cdef object _int64(const CassValue * cass_value)
cdef object _uuid(const CassValue * cass_value, int8_t flags)
cdef object _float(const CassValue * cass_value)
cdef object _double(const CassValue * cass_value)
cdef object _decimal(const CassValue * cass_value, int8_t flags)
cdef object _bool(const CassValue * cass_value)
cdef object _string(const CassValue * cass_value)
cdef object _bytes(const CassValue * cass_value)
cdef object _inet(const CassValue * cass_value)
cdef object _date(const CassValue * cass_value, int8_t flags)
cdef object _time(const CassValue * cass_value, int8_t flags)
cdef object _timestamp(const CassValue * cass_value, int8_t flags)
cdef object _duration(const CassValue * cass_value, int8_t flags)
cdef object _map(const CassValue * cass_value, int8_t flags)
cdef object _set(const CassValue * cass_value, int8_t flags)
cdef object _list(const CassValue * cass_value, int8_t flags)
cdef object _tuple(const CassValue * cass_value, int8_t flags)
cdef object _udt(const CassValue * cass_value, int8_t flags)
cdef object get_cass_value(const CassValue * cass_value, int8_t flags)
