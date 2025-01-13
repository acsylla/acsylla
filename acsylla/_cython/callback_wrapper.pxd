cdef class CallbackWrapper:
    cdef:
        object future
        Cluster cluster
    cdef void set_result(self)

    @staticmethod
    cdef CallbackWrapper new_(CassFuture* cass_future, Cluster cluster)
