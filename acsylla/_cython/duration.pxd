cdef class Duration:
    cdef readonly int months
    cdef readonly int days
    cdef readonly long long nanoseconds

    @staticmethod
    cdef Duration new_(int months, int days, long long nanoseconds)
