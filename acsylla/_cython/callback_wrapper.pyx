cdef class CallbackWrapper:

    def __cinit__(self):
        self.cass_future = NULL

    def __dealloc__(self):
        cass_future_free(self.cass_future)

    async def __await__(self):
        await self.future
    
    @staticmethod
    cdef void cb(CassFuture* cass_future, void* data) with gil:
        cdef CallbackWrapper cb_wrapper = <CallbackWrapper>data
 
        if cb_wrapper.future.done():
            return

        cb_wrapper.future.set_result()

    @staticmethod
    cdef CallbackWrapper new_(CassFuture* cass_future, object loop):
        cdef CallbackWrapper cb_wrapper

        cb_wrapper = CallbackWrapper()
        cb_wrapper.future = loop.create_future()
        cb_wrapper.cass_future = cass_future

        error = cass_future_set_callback(
            cb_wrapper.cass_future,
            CallbackWrapper.cb,
            <void*> cb_wrapper
        ) 
        if error != CASS_OK:
            raise RuntimeError(error)

        return cb_wrapper

