import asyncio

cdef class Session:

    def __cinit__(self, Cluster cluster, object keyspace):
        self.cass_cluster = cluster.cass_cluster
        self.cass_session = cass_session_new()
  
    def __dealloc__(self):
        cass_session_free(self.cass_session)

    def __init__(self, cass_cluster, keyspace=None):
        self.loop = asyncio.get_running_loop()
        self.keyspace = keyspace
        self.closed = 0
        self.connected = 0

    async def close(self):
        cdef CallbackWrapper cb_wrapper
        cdef CassFuture* cass_future

        if self.closed == 1:
            return

        # Not really closed but on our way
        # of closing it.
        self.closed = 1

        cb_wrapper = CallbackWrapper.new_(
            cass_session_close(self.cass_session),
            self.loop
        )

        await cb_wrapper.__await__()

    async def _connect(self):
        cdef bytes keyspace
        cdef CallbackWrapper cb_wrapper
        cdef CassFuture* cass_future

        if self.closed == 1:
            raise RuntimeError("Session closed")

        if self.connected == 1:
            raise RuntimeError("Session already connected")

        # Not really connected but on our way
        # of connecting it.
        self.connected = 1

        if self.keyspace is not None:
            keyspace = self.keyspace.encode()
            cb_wrapper = CallbackWrapper.new_(
                cass_session_connect_keyspace_n(
                    self.cass_session,
                    self.cass_cluster,
                    keyspace,
                    len(keyspace)
                ),
                self.loop
            )
        else:
            cb_wrapper = CallbackWrapper.new_(
                cass_session_connect(self.cass_session, self.cass_cluster),
                self.loop
            )

        await cb_wrapper.__await__()

    async def execute(self, bytes statement):
        cdef CallbackWrapper cb_wrapper
        cdef CassStatement* cass_statement
        cdef CassFuture* cass_future

        if self.closed == 1:
            raise RuntimeError("Session closed")

        if self.connected == 0:
            raise RuntimeError("Session not connected")

        if self.keyspace is None:
            raise RuntimeError("Raw queries need to use a session connected to a keyspace")

        cass_statement = cass_statement_new_n(
            statement,
            len(statement),
            0
        )

        cb_wrapper = CallbackWrapper.new_(
            cass_session_execute(self.cass_session, cass_statement),
            self.loop
        )

        try:
            await cb_wrapper.__await__()
        except CallbackError as callback_error:
            if callback_error.cass_error == CASS_ERROR_SYNTAX_ERROR:
                raise CassExceptionSyntaxError(statement)
            else:
                raise CassException(callback_error.cass_error)
        finally:
            cass_statement_free(cass_statement)
