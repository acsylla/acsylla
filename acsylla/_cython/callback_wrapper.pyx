cdef class CallbackWrapper:

    def __cinit__(self):
        self.cass_future = NULL

    def __dealloc__(self):
        cass_future_free(self.cass_future)

    async def __await__(self):
        await self.future
    
    cdef void set_result(self):
        cdef const CassErrorResult* error_result
        cdef CassError error

        if self.future.done():
            return

        error_result = cass_future_get_error_result(self.cass_future)
        if error_result == NULL: 
            # NULL means no error reported
            self.future.set_result(None)
            return

        error = cass_error_result_code(error_result)
        cass_error_result_free(error_result)
        self.future.set_exception(Exception(error))

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
