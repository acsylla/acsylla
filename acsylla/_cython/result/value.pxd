cdef class Value:
    cdef:
        const CassValue* cass_value

    @staticmethod
    cdef Value new_(CassValue* cass_value)

    cdef int _int(self)
    cdef TypeUUID _uuid(self)
    cdef float _float(self)
    cdef object _bool(self)
    cdef str _string(self)
    cdef bytes _bytes(self)
