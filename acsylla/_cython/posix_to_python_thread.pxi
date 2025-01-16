from libcpp.memory cimport shared_ptr

cdef extern from "Python.h":
    void Py_INCREF(object o)
    void Py_DECREF(object o)
    Py_ssize_t Py_REFCNT(object o)

cdef extern from "<queue>" namespace "std" nogil:
    cdef cppclass queue[T]:
        queue()
        bint empty()
        T& front()
        void pop()
        void push(T&)
        size_t size()

cdef extern from "<mutex>" namespace "std" nogil:
    cdef cppclass mutex:
        mutex()
        void lock()
        void unlock()

cdef extern from "posix_to_python_thread.cpp" nogil:
    cdef cppclass PosixToPython:
        PosixToPython(int write_fd)
        int write_fd
        mutex _queue_mutex
        queue[void *] _queue

    cdef cppclass CallbackContainer:
        CallbackContainer(PosixToPython* handler, void* data)

    void posix_to_python_callback(CassFuture* cass_future, void* data)

    cdef cppclass PosixToPythonLogger:
        PosixToPythonLogger(int write_fd)
        int write_fd
        mutex _queue_mutex
        queue[shared_ptr[CassLogMessage]] _queue

    void posix_to_python_logger_callback(const CassLogMessage* message, void* data)

    ctypedef struct HostListenerMessage:
        CassHostListenerEvent event
        char address[CASS_INET_STRING_LENGTH]

    cdef cppclass PosixToPythonHostListener:
        PosixToPythonHostListener(int write_fd)
        int write_fd
        mutex _queue_mutex
        queue[shared_ptr[HostListenerMessage]] _queue

    void posix_to_python_host_listener_callback(CassHostListenerEvent event, const CassInet address, void* data)
