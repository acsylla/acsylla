import asyncio
import logging
import socket

from libc.stdlib cimport free
from libcpp.memory cimport shared_ptr

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
        loop = asyncio.get_running_loop()
        loop.add_reader(self._read_socket, self._handle_message)
        self.posix_to_python = new PosixToPythonLogger(self._write_socket.fileno())
        cass_log_set_callback(<CassLogCallback>posix_to_python_logger_callback, <void*>self.posix_to_python)

    def __init__(self, log_level='warn', logging_callback=None):
        self.set_log_level(log_level)
        self.logging_callback = logging_callback

    def __dealloc__(self):
        cass_log_set_callback(NULL, NULL)
        del self.posix_to_python

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

    def _handle_message(self):
        cdef bytes _ = self._read_socket.recv(1)
        cdef shared_ptr[CassLogMessage] data
        cdef CassLogMessage* message

        while True:
            self.posix_to_python._queue_mutex.lock()
            try:
                if not self.posix_to_python._queue.empty():
                    data = self.posix_to_python._queue.front()
                    self.posix_to_python._queue.pop()
                    message = data.get()
                else:
                    break
            finally:
                self.posix_to_python._queue_mutex.unlock()

            log_level = cass_log_level_string(message.severity).decode()
            log_message = message.message.decode()

            if self.logging_callback is not None:
                from acsylla import LogMessage
                log = LogMessage(
                    time_ms=message.time_ms,
                    log_level=log_level,
                    file=message.file.decode(),
                    line=message.line,
                    function=message.function.decode(),
                    message=log_message
                )
                if asyncio.iscoroutinefunction(self.logging_callback):
                    asyncio.create_task(self.logging_callback(log))
                else:
                    self.logging_callback(log)
            else:
                logger_fn = self.logger_fn.get(log_level)
                if logger_fn:
                    logger_fn(log_message)

            free(<void*>message.file)
            free(<void*>message.function)

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