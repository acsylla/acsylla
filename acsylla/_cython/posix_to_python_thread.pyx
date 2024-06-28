# We use that module for comunicating from a posix world, where
# Cassandra CPP driver is being executed, that a CassFuture
# has finished by waking up the Python Event loop and executing
# the proper CallbackWrapper code which is placed in a Python Thread.
#
# From a posix thread wont be possible to execute any code that
# touches the CPython interace if the GIL structures for that thread 
# are not intialized, because the caller thread is started by the Cassandra
# CPP driver we do not have any chance of initalizing that thread.
import socket
import threading

from libc.string cimport strcpy
from posix cimport unistd


cdef int _socket_write(int fd) noexcept nogil:
    return unistd.write(fd, b"1", 1)

cdef int _socket_close(int fd) noexcept nogil:
    return unistd.close(fd)


cdef void cb_cass_future(CassFuture* cass_future, void* data):
    """ Function called from the POSIX Thread, no Python objects
    are touched. A CassFuture has finished, we add it to the queue
    and tell the Asyncio Loop that there is data to be processed.
    """
    global _write_fd, _queue
    _queue_mutex.lock()
    _queue.push(data)
    _queue_mutex.unlock()
    _socket_write(_write_fd)

cdef void cb_log_message(const CassLogMessage* message, void* data):
    global _log_write_fd, _log_queue
    cdef LogMessageCallback cb
    cb.msg.time_ms = message.time_ms
    cb.msg.severity = message.severity
    cb.msg.file = message.file
    cb.msg.line = message.line
    cb.msg.function = message.function
    cb.logger = data
    strcpy(cb.msg.message, message.message)
    _log_queue_mutex.lock()
    _log_queue.push(cb)
    _log_queue_mutex.unlock()
    _socket_write(_log_write_fd)


def _handle_log_message():
    cdef bytes _ = _log_read_socket.recv(1)
    cdef LogMessageCallback data

    _log_queue_mutex.lock()
    data = _log_queue.front()
    _log_queue.pop()
    _log_queue_mutex.unlock()

    logger = <Logger>data.logger
    from acsylla import LogMessage
    logger.log(LogMessage(
        time_ms=data.msg.time_ms,
        log_level=cass_log_level_string(data.msg.severity).decode(),
        file=data.msg.file.decode(),
        line=data.msg.line,
        function=data.msg.function.decode(),
        message=data.msg.message.decode()
    ))

def _handle_events():
    """ Function called from the Asyncio Loop because some
    data was added into the queue, it gets from the queue
    the data and calls the corresponding CallbackWrappers.
    """
    cdef bytes _ = _read_socket.recv(1)
    cdef void* data
    cdef CallbackWrapper cb_wrapper

    while True:
        _queue_mutex.lock()
        if _queue.empty():
            _queue_mutex.unlock()
            break
        else:
            data = _queue.front()
            _queue.pop()
            _queue_mutex.unlock()

        cb_wrapper = <CallbackWrapper> data
        cb_wrapper.set_result()
        Py_DECREF(cb_wrapper)

_lock = threading.Lock()

cdef _initialize_posix_to_python_thread():
    cdef object current_loop
    global _lock, _loop, _read_socket, _log_read_socket, _write_socket, _log_write_socket, _write_fd, _log_write_fd, _queue, _log_queue, _thread_id

    with _lock:

        current_loop = asyncio.get_running_loop()

        if _loop is None:
            _thread_id = threading.get_ident()
            _loop = current_loop
            _read_socket, _write_socket = socket.socketpair()
            _write_fd = _write_socket.fileno()
            _queue = cpp_event_queue()
            _loop.add_reader(_read_socket, _handle_events)
            _log_read_socket, _log_write_socket = socket.socketpair()
            _log_write_fd = _log_write_socket.fileno()
            _log_queue = cpp_log_queue()
            _loop.add_reader(_log_read_socket, _handle_log_message)
        elif _loop != current_loop:
            # Either the loop has been recreated for the current thread
            # or a new thread with a new asyncio loop has been started.

            # for now new threads are not supported, they could be
            # suppoted in the future.
            assert threading.get_ident() == _thread_id, "More than one thread and loop not supported yet"

            # If same main thread just started a new loop, we support it by
            # adding the proper handlers to the loop
            _loop = current_loop
            _loop.add_reader(_read_socket, _handle_events)
            _loop.add_reader(_log_read_socket, _handle_log_message)
        else:
            return


