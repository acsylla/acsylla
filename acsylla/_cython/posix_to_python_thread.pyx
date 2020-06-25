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


IF UNAME_SYSNAME == "Windows":
    cdef void _unified_socket_write(int fd) nogil:
        win_socket_send(<WIN_SOCKET>fd, b"1", 1, 0)
ELSE:
    from posix cimport unistd

    cdef void _unified_socket_write(int fd) nogil:
        unistd.write(fd, b"1", 1)


cdef void cb_cass_future(CassFuture* cass_future, void* data):
    """ Function called from the POSIX Thread, no Python objects
    are touched. A CassFuture has finished, we add it to the queue
    and tell the Asyncio Loop that there is data to be processed.
    """
    global _write_fd, _queue
    _queue_mutex.lock()
    _queue.push(data)
    _queue_mutex.unlock()
    _unified_socket_write(_write_fd)


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

_lock = threading.Lock()

cdef _initialize_posix_to_python_thread():
    global _lock, _initialized, _read_socket, _write_socket, _write_fd, _queue
    with _lock:
        if _initialized == 0:
            _read_socket, _write_socket = socket.socketpair()
            _write_fd = _write_socket.fileno()
            _queue = cpp_event_queue()
            asyncio.get_running_loop().add_reader(_read_socket, _handle_events)
            _initialized = 1
