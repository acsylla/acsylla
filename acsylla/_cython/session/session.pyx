import asyncio


cdef class Session:
    def __cinit__(self, Cluster cluster, object keyspace):
        self.cass_cluster = cluster.cass_cluster
        self.cass_session = cass_session_new()

    def __dealloc__(self):
        cass_session_free(self.cass_session)
        if self.schema_meta:
            cass_schema_meta_free(self.schema_meta)

    def __init__(self, cass_cluster, keyspace=None):
        self.loop = asyncio.get_running_loop()
        self.keyspace = keyspace
        self.closed = 0
        self.connected = 0

    async def _connect(self):
        cdef CassFuture* cass_future
        cdef CassError cass_error
        cdef size_t length = 0
        cdef char* error_message = NULL

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
            cass_error = cass_future_error_code(cass_future)
            cass_future_error_message(cass_future, <const char**> &error_message, <size_t *> &length)
            raise_if_error(cass_error, error_message)
        finally:
            cass_future_free(cass_future)

    async def close(self):
        cdef CassFuture* cass_future
        cdef CassError cass_error
        cdef size_t length = 0
        cdef char* error_message = NULL

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
            cass_error = cass_future_error_code(cass_future)
            cass_future_error_message(cass_future, <const char**> &error_message, <size_t *> &length)
            raise_if_error(cass_error, error_message)
        finally:
            cass_future_free(cass_future)


    async def execute(self, Statement statement):
        """ Execute an statement and returns the result.

        Is responsability of the caller to know what to do with
        the results object.
        """
        cdef CassFuture* cass_future
        cdef CassError cass_error
        cdef size_t length = 0
        cdef char* error_message = NULL
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
                cass_error = cass_future_error_code(cass_future)
                cass_future_error_message(cass_future, <const char**> &error_message, <size_t*> &length)
                raise_if_error(cass_error, error_message)

            result = Result.new_(cass_result)
        finally:
            cass_future_free(cass_future)

        return result

    async def create_prepared(self, str statement, object timeout=None, object consistency=None):
        """ Prepares an statement."""
        cdef CassFuture* cass_future
        cdef CassError cass_error
        cdef size_t length = 0
        cdef char* error_message = NULL
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
                cass_error = cass_future_error_code(cass_future)
                cass_future_error_message(cass_future, <const char**> &error_message, <size_t *> &length)
                raise_if_error(cass_error, error_message)
            self.schema_meta = cass_session_get_schema_meta(self.cass_session)
            if self.keyspace is not None:
                keyspace = self.keyspace.encode()
                self.keyspace_meta = cass_schema_meta_keyspace_by_name(self.schema_meta, keyspace)

            prepared = PreparedStatement.new_(cass_prepared, timeout, consistency)
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
        cdef size_t length = 0
        cdef char* error_message = NULL
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
                cass_error = cass_future_error_code(cass_future)
                cass_future_error_message(cass_future, <const char**> &error_message, <size_t*> &length)
                raise_if_error(cass_error, error_message)
        finally:
            cass_future_free(cass_future)

    def metrics(self):
        """ Returns performance metrics gathered by the driver.

        Returns a `acsylla.Metrics` object.
        """
        cdef CassMetrics cass_metrics

        cass_session_get_metrics(self.cass_session, &cass_metrics)

        # Python code is only available at runtime, we can not export this
        # as a simple Python module and we are forced to do so at runtime.
        # Otherwise compilation will fail.

        # metrics method should be called from time to time, having a
        # check or a load the Metrics object should not have a significant
        # impact.
        from acsylla import SessionMetrics
        return SessionMetrics(
            requests_min=int(cass_metrics.requests.min),
            requests_max=int(cass_metrics.requests.max),
            requests_mean=int(cass_metrics.requests.mean),
            requests_stddev=int(cass_metrics.requests.stddev),
            requests_median=int(cass_metrics.requests.median),
            requests_percentile_75th=int(cass_metrics.requests.percentile_75th),
            requests_percentile_95th=int(cass_metrics.requests.percentile_95th),
            requests_percentile_98th=int(cass_metrics.requests.percentile_98th),
            requests_percentile_99th=int(cass_metrics.requests.percentile_99th),
            requests_percentile_999th=int(cass_metrics.requests.percentile_999th),
            requests_mean_rate=cass_metrics.requests.mean_rate,
            requests_one_minute_rate=cass_metrics.requests.one_minute_rate,
            requests_five_minute_rate=cass_metrics.requests.five_minute_rate,
            requests_fifteen_minute_rate=cass_metrics.requests.fifteen_minute_rate,
            stats_total_connections=int(cass_metrics.stats.total_connections),
            errors_connection_timeouts=int(cass_metrics.errors.connection_timeouts),
            errors_request_timeouts=int(cass_metrics.errors.request_timeouts)
        )
