CASS_ERROR_SYNTAX_ERROR = 2 << 24 | 0x2000


class CallbackError(Exception):
    """ Generic exception used for storing the error number that
    generated the callback error.

    Later on upper layers can create their own ad-hoc Exceptions
    for making the error less generics.
    """
    def __init__(self, object cass_error):
        self.cass_error = cass_error


cdef class CallbackWrapper:

    def __cinit__(self):
        self.cass_future = NULL

    def __dealloc__(self):
        cass_future_free(self.cass_future)

    async def __await__(self):
        result = await self.future
        return result
    
    cdef void set_result(self):
        cdef const CassErrorResult* error_result
        cdef CassError error
        cdef const CassResult* cass_result = NULL
        cdef Result result

        if self.future.done():
            return

        error_result = cass_future_get_error_result(self.cass_future)
        if error_result == NULL: 
            cass_result = cass_future_get_result(self.cass_future)
            if cass_result != NULL:
                result = Result.new_(cass_result)
                self.future.set_result(result)
            else:
                self.future.set_result(None)
            return

        error = cass_error_result_code(error_result)
        cass_error_result_free(error_result)
        self.future.set_exception(CallbackError(error))

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
