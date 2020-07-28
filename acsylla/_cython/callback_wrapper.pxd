cdef class CallbackWrapper:
    cdef:
        object future

    cdef void set_result(self)

    @staticmethod
    cdef CallbackWrapper new_(CassFuture* cass_future, object loop)
