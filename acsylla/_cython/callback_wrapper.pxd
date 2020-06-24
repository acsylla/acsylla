cdef class CallbackWrapper:
    cdef:
        CassFuture* cass_future
        object future

    @staticmethod
    cdef CallbackWrapper new_(CassFuture* cass_future, object loop)

    @staticmethod
    cdef void cb(CassFuture* future, void* data) with gil
    
