import logging

from libc.string cimport strcpy
from posix cimport unistd

logger = logging.getLogger('acsylla')

cdef log_level_from_str(object level):
    levels = {
        'disabled': CASS_LOG_DISABLED,
        'critical': CASS_LOG_CRITICAL,
        'error': CASS_LOG_ERROR,
        'warn': CASS_LOG_WARN,
        'warning': CASS_LOG_WARN,
        'info': CASS_LOG_INFO,
        'debug': CASS_LOG_DEBUG,
        'trace': CASS_LOG_TRACE,
    }
    return levels[level.lower()]


cdef class Logger:
    logger_fn = {
        'CRITICAL': logger.critical,
        'ERROR': logger.error,
        'WARN': logger.warning,
        'INFO': logger.info,
        'DEBUG': logger.debug,
        'TRACE': logger.debug
    }
    levels = {
        'disabled': None,
        'critical': logging.CRITICAL,
        'error': logging.ERROR,
        'warn': logging.WARNING,
        'warning': logging.WARNING,
        'info': logging.INFO,
        'debug': logging.DEBUG,
        'trace': logging.DEBUG
    }

    def __cinit__(self):
        self._read_socket, self._write_socket = socket.socketpair()
        self._write_fd = self._write_socket.fileno()
        loop = asyncio.get_running_loop()
        loop.add_reader(self._read_socket, self._handle_message)
        cass_log_set_callback(<CassLogCallback>self.log_message_callback, <void*>self)

    def __init__(self, log_level='warn', logging_callback=None):
        self.set_log_level(log_level)
        self.logging_callback = logging_callback

    def destroy(self):
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            return
        if self._read_socket and self._read_socket.fileno():
            loop.remove_reader(self._read_socket)
            self._read_socket.close()
            self._read_socket = None
        if self._write_socket:
            self._write_socket.close()
            self._write_socket = None

    cdef int _socket_write(self, int fd) noexcept nogil:
        return unistd.write(fd, b"1", 1)

    @staticmethod
    cdef void log_message_callback(const CassLogMessage* message, void* data):
        cdef CassLogMessage msg

        msg.time_ms = message.time_ms
        msg.severity = message.severity
        msg.file = message.file
        msg.line = message.line
        msg.function = message.function
        strcpy(msg.message, message.message)

        self = <Logger>data
        self._queue_mutex.lock()
        self._queue.push(msg)
        self._queue_mutex.unlock()
        self._socket_write(self._write_fd)

    def _handle_message(self):
        cdef bytes _ = self._read_socket.recv(1)
        cdef CassLogMessage message

        self._queue_mutex.lock()
        data = self._queue.front()
        self._queue.pop()
        self._queue_mutex.unlock()

        message = <CassLogMessage>data

        from acsylla import LogMessage

        msg = LogMessage(
            time_ms=message.time_ms,
            log_level=cass_log_level_string(message.severity).decode(),
            file=message.file.decode(),
            line=message.line,
            function=message.function.decode(),
            message=message.message.decode()
        )
        if self.logging_callback is not None:
            if asyncio.iscoroutinefunction(self.logging_callback):
                asyncio.create_task(self.logging_callback(msg))
            else:
                self.logging_callback(msg)
        else:
            self.logger_fn[msg.log_level](msg.message)


    def set_log_level(self, level):
        if level is not None:
            try:
                cass_log_set_level(log_level_from_str(level))
            except KeyError:
                raise ValueError(f'Unknown log_level "{level}". '
                                 f'Log level must be one of ({", ".join(self.levels.keys())})')
            log_level = self.levels[level.lower()]
            if log_level is not None:
                logger.setLevel(log_level)

    def set_logging_callback(self, callback):
        self.logging_callback = callback

    def get_logger(self):
        return logger
