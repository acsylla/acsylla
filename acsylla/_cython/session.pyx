import asyncio

cdef class Session:

    def __cinit__(self, Cluster cluster):
        self.cass_cluster = cluster.cass_cluster
        self.cass_session = cass_session_new()
  
    def __dealloc__(self):
        cass_session_free(self.cass_session)

    def __init__(self, cass_cluster):
        self.loop = asyncio.get_running_loop()

    async def _connect(self):
        cdef CallbackWrapper cb_wrapper
        cdef CassError error
        cdef CassFuture* cass_future

        cb_wrapper = CallbackWrapper.new_(
            cass_session_connect(self.cass_session, self.cass_cluster),
            self.loop
        )

        try:
            await cb_wrapper
        finally:
            cass_future_free(cass_future)
