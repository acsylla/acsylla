cdef class Logger:
    cdef:
        object logging_callback
        object log

cdef log_level_from_str(object level)