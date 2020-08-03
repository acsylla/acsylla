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

    cdef _raise_if_error(self, CassFuture * cass_future):
        cdef CassError cass_error

        cass_error = cass_future_error_code(cass_future)
        if cass_error == CASS_OK:
            return

        if cass_error == CASS_ERROR_LIB_NO_HOSTS_AVAILABLE:
            raise CassExceptionConnectionError()
        elif cass_error == CASS_ERROR_SERVER_SYNTAX_ERROR:
            raise CassExceptionSyntaxError()
        elif cass_error == CASS_ERROR_SERVER_INVALID_QUERY:
            raise CassExceptionInvalidQuery()
        else:
            raise CassException(cass_error)

    async def close(self):
        cdef CassFuture* cass_future
        cdef CassError cass_error

        cdef CallbackWrapper cb_wrapper

        if self.closed == 1:
            return

        # Not really closed but on our way
        # of closing it.
        self.closed = 1

        cass_future = cass_session_close(self.cass_session)
        cb_wrapper = CallbackWrapper.new_(cass_future, self.loop)

        try:
            await cb_wrapper.__await__()
            self._raise_if_error(cass_future)
        finally:
            cass_future_free(cass_future)

    async def _connect(self):
        cdef CassFuture* cass_future
        cdef CassError cass_error

        cdef bytes keyspace
        cdef CallbackWrapper cb_wrapper

        if self.keyspace is not None:
            keyspace = self.keyspace.encode()
            cass_future = cass_session_connect_keyspace_n(
                self.cass_session,
                self.cass_cluster,
                keyspace,
                len(keyspace)
            )
        else:
            cass_future = cass_session_connect(self.cass_session, self.cass_cluster)

        cb_wrapper = CallbackWrapper.new_(cass_future, self.loop)

        try:
            await cb_wrapper.__await__()
            self._raise_if_error(cass_future)
        finally:
            cass_future_free(cass_future)

    async def execute(self, Statement statement):
        """ Execute an statement and returns the result.

        Is responsability of the caller to know what to do with
        the results object.
        """
        cdef CassFuture* cass_future
        cdef CassError cass_error
        cdef const CassResult* cass_result = NULL

        cdef Result result
        cdef CallbackWrapper cb_wrapper

        if self.closed == 1:
            raise RuntimeError("Session closed")

        cass_future = cass_session_execute(self.cass_session, statement.cass_statement)
        cb_wrapper = CallbackWrapper.new_(cass_future, self.loop)

        try:
            await cb_wrapper.__await__()
            cass_result = cass_future_get_result(cass_future)
            if cass_result == NULL:
                self._raise_if_error(cass_future)

            result = Result.new_(cass_result)
        finally:
            cass_future_free(cass_future)

        return result

    async def create_prepared(self, str statement):
        """ Prepares an statement."""
        cdef CassFuture* cass_future
        cdef CassError cass_error
        cdef const CassPrepared* cass_prepared

        cdef bytes encoded_statement
        cdef PreparedStatement prepared
        cdef CallbackWrapper cb_wrapper

        if self.closed == 1:
            raise RuntimeError("Session closed")

        encoded_statement = statement.encode()

        cass_future = cass_session_prepare_n(self.cass_session, encoded_statement, len(encoded_statement))
        cb_wrapper = CallbackWrapper.new_(cass_future, self.loop)

        try:
            await cb_wrapper.__await__()
            cass_prepared = cass_future_get_prepared(cass_future)
            if cass_prepared == NULL:
                self._raise_if_error(cass_future)

            prepared = PreparedStatement.new_(cass_prepared)
        finally:
            cass_future_free(cass_future)

        return prepared

    async def execute_batch(self, Batch batch):
        """ Execute a batch of statements and returns the result.

        Is responsability of the caller to know what to do with
        the results object.
        """
        cdef CassFuture* cass_future
        cdef CassError cass_error
        cdef const CassResult* cass_result = NULL

        cdef CallbackWrapper cb_wrapper

        if self.closed == 1:
            raise RuntimeError("Session closed")

        cass_future = cass_session_execute_batch(self.cass_session, batch.cass_batch)
        cb_wrapper = CallbackWrapper.new_(cass_future, self.loop)

        try:
            await cb_wrapper.__await__()
            cass_result = cass_future_get_result(cass_future)
            if cass_result == NULL:
                self._raise_if_error(cass_future)
        finally:
            cass_future_free(cass_future)
