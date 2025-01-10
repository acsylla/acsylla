cdef class Logger:
    cdef:
        object logging_callback
        object log
        queue[CassLogMessage] _queue
        mutex _queue_mutex
        int _write_fd
        object _read_socket
        object _write_socket

    @staticmethod
    cdef void log_message_callback(const CassLogMessage* message, void* data)
    cdef int _socket_write(self, int fd) noexcept nogil

cdef log_level_from_str(object level)