cdef class CallbackWrapper:

    def __cinit__(self):
        self.cass_future = NULL

    def __dealloc__(self):
        cass_future_free(self.cass_future)

    async def __await__(self):
        await self.future
    
    cdef void set_result(self):
        if self.future.done():
            return

        self.future.set_result(None)

    @staticmethod
    cdef CallbackWrapper new_(CassFuture* cass_future, object loop):
        cdef CallbackWrapper cb_wrapper

        cb_wrapper = CallbackWrapper()
        cb_wrapper.future = loop.create_future()
        cb_wrapper.cass_future = cass_future

        error = cass_future_set_callback(
            cb_wrapper.cass_future,
            cb_cass_future,
            <void*> cb_wrapper
        ) 
        if error != CASS_OK:
            raise RuntimeError(error)

        return cb_wrapper
