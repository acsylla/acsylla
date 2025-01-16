import socket

from libcpp.memory cimport shared_ptr


cdef class HostListener:
    def __cinit__(self):
        self._read_socket, self._write_socket = socket.socketpair()
        loop = asyncio.get_running_loop()
        loop.add_reader(self._read_socket, self._handle_message)
        self.posix_to_python = new PosixToPythonHostListener(self._write_socket.fileno())

    cdef init(self, CassCluster* cass_cluster, callback):
        self.host_listener_callback = callback
        error = cass_cluster_set_host_listener_callback(<CassCluster*>cass_cluster, <CassHostListenerCallback>posix_to_python_host_listener_callback, <void*>self.posix_to_python)
        raise_if_error(error)

    def destroy(self):
        #error = cass_cluster_set_host_listener_callback(<CassCluster*>cass_cluster, NULL, NULL)
        #raise_if_error(error)

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

    def _handle_message(self):
        cdef shared_ptr[HostListenerMessage] data
        cdef HostListenerMessage* message
        cdef bytes _ = self._read_socket.recv(1)
        self.posix_to_python._queue_mutex.lock()
        data = self.posix_to_python._queue.front()
        self.posix_to_python._queue.pop()
        self.posix_to_python._queue_mutex.unlock()
        message = data.get()
        if self.host_listener_callback is not None:
            from acsylla import HostListenerEvent
            event = HostListenerEvent(message.event)
            if asyncio.iscoroutinefunction(self.host_listener_callback):
                asyncio.create_task(self.host_listener_callback(event, message.address.decode()))
            else:
                self.host_listener_callback(event, message.address.decode())

    def set_host_listener_callback(self, callback):
        self.host_listener_callback = callback
