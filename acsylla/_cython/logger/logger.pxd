cdef class Logger:
    cdef:
        object _read_socket
        object _write_socket
        PosixToPythonLogger* posix_to_python
        object logging_callback

cdef log_level_from_str(object level)