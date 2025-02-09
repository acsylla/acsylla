cdef class CallbackWrapper:

    async def __await__(self):
        result = await self.future
        return result
    
    cdef void set_result(self):
        if self.future.done():
            return

        self.future.set_result(None)

    @staticmethod
    cdef CallbackWrapper new_(CassFuture* cass_future, Cluster cluster):
        cdef CallbackWrapper cb_wrapper

        cb_wrapper = CallbackWrapper()
        cb_wrapper.future = cluster.loop.create_future()
        Py_INCREF(cb_wrapper)

        cdef CallbackContainer* container
        container = new CallbackContainer(<PosixToPython*>cluster.posix_to_python, <void*>cb_wrapper)
        error = cass_future_set_callback(
            cass_future,
            <CassFutureCallback>posix_to_python_callback,
            <void*>container
        )
        if error != CASS_OK:
            Py_DECREF(cb_wrapper)
            raise_if_error(error)

        return cb_wrapper
