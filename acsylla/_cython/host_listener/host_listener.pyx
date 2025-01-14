import socket

from posix cimport unistd


cdef class HostListener:
    def __cinit__(self):
        self._read_socket, self._write_socket = socket.socketpair()
        self._write_fd = self._write_socket.fileno()
        loop = asyncio.get_running_loop()
        loop.add_reader(self._read_socket, self._handle_message)

    cdef init(self, CassCluster* cass_cluster, callback):
        self.host_listener_callback = callback
        error = cass_cluster_set_host_listener_callback(<CassCluster*>cass_cluster, <CassHostListenerCallback>self._callback, <void*>self)
        raise_if_error(error)

    def destroy(self):
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            return

        if self._read_socket:
            loop.remove_reader(self._read_socket)
            self._read_socket.close()
            self._read_socket = None

        if self._write_socket:
            self._write_socket.close()
            self._write_socket = None

    cdef int _socket_write(self, int fd) noexcept nogil:
        return unistd.write(fd, b"1", 1)

    @staticmethod
    cdef void _callback(CassHostListenerEvent event, const CassInet address, void* data):
        self = <HostListener>data
        cdef HostListenerMessage message
        message.event = event
        message.address = address
        self._mutex.lock()
        self._queue.push(message)
        self._mutex.unlock()
        self._socket_write(self._write_fd)

    def _handle_message(self):
        cdef bytes _ = self._read_socket.recv(1)
        cdef char address[CASS_INET_STRING_LENGTH]
        self._mutex.lock()
        message = self._queue.front()
        self._queue.pop()
        self._mutex.unlock()
        if self.host_listener_callback is not None:
            from acsylla import HostListenerEvent
            cass_inet_string(message.address, address)
            if asyncio.iscoroutinefunction(self.host_listener_callback):
                asyncio.create_task(self.host_listener_callback(HostListenerEvent(message.event), address.decode()))
            else:
                self.host_listener_callback(HostListenerEvent(message.event), address.decode())

    def set_host_listener_callback(self, callback):
        self.host_listener_callback = callback
