import socket

from posix cimport unistd


cdef class HostListener:
    def __cinit__(self):
        self._queue = _host_listener_queue()
        self._read_socket, self._write_socket = socket.socketpair()
        self._write_fd = self._write_socket.fileno()
        loop = asyncio.get_running_loop()
        loop.add_reader(self._read_socket, self._handle_message)

    cdef void _write(self, int fd) nogil:
        unistd.write(fd, b"1", 1)

    @staticmethod
    cdef void _callback(CassHostListenerEvent event, CassInet inet, void* data):
        self = <HostListener>data
        cdef HostListenerMessage message
        message.event = event
        message.inet = inet
        self._mutex.lock()
        self._queue.push(message)
        self._mutex.unlock()
        self._write(self._write_fd)

    def _handle_message(self):
        cdef bytes _ = self._read_socket.recv(1)
        cdef char address[CASS_INET_STRING_LENGTH]
        self._mutex.lock()
        message = self._queue.front()
        self._queue.pop()
        self._mutex.unlock()
        if self.host_listener_callback is not None:
            from acsylla import HostListenerEvent
            cass_inet_string(message.inet, address)
            self.host_listener_callback(HostListenerEvent(message.event), address.decode())

    def free(self):
        try:
            loop = asyncio.get_running_loop()
            if self._read_socket.fileno():
                loop.remove_reader(self._read_socket)
        except RuntimeError:
            return
        self._read_socket.close()
        self._write_socket.close()

    cdef init(self, CassCluster* cass_cluster, callback):
        self.host_listener_callback = callback
        cass_cluster_set_host_listener_callback(<CassCluster*>cass_cluster, <CassHostListenerCallback>self._callback, <void*>self)

    def set_host_listener_callback(self, callback):
        self.host_listener_callback = callback
