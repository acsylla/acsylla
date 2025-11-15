cdef class Batch:

    def __cinit__(self):
        self.cass_batch = NULL

    def __dealloc__(self):
        cass_batch_free(self.cass_batch)

    @staticmethod
    cdef Batch new_(CassBatchType type_, object timeout, str execution_profile):
        cdef CassError error
        cdef Batch batch
        cdef int timeout_ms

        batch = Batch()
        batch.cass_batch = cass_batch_new(type_)

        if timeout is not None:
            timeout_ms = int(timeout * 1000)
            error = cass_batch_set_request_timeout(batch.cass_batch, timeout_ms)
            raise_if_error(error)
        if execution_profile is not None:
            batch.set_execution_profile(execution_profile)
        return batch

    def set_consistency(self, object consistency):
        if consistency is not None:
            error = cass_batch_set_consistency(self.cass_batch, consistency.value)
            raise_if_error(error)

    def set_serial_consistency(self, object consistency):
        if consistency is not None:
            error =  cass_batch_set_serial_consistency(self.cass_batch, consistency.value)
            raise_if_error(error)

    def set_timestamp(self, timestamp: object):
        if timestamp is not None:
            error =  cass_batch_set_timestamp(self.cass_batch, int(timestamp))
            raise_if_error(error)

    def set_request_timeout(self, timeout_ms: int):
        cdef CassError error
        if timeout_ms is not None:
            error = cass_batch_set_request_timeout(self.cass_batch, timeout_ms)
            raise_if_error(error)

    def set_is_idempotent(self, is_idempotent):
        cdef CassError error
        if is_idempotent is not None:
            error = cass_batch_set_is_idempotent(self.cass_batch, is_idempotent)
            raise_if_error(error)

    def set_retry_policy(self, retry_policy: object, retry_policy_logging: bool = False):
        cdef CassError error
        cdef CassRetryPolicy* cass_policy
        cdef CassRetryPolicy* cass_log_policy
        if retry_policy is not None:
            if retry_policy == 'default':
                cass_policy = cass_retry_policy_default_new()
            elif retry_policy == 'fallthrough':
                cass_policy = cass_retry_policy_fallthrough_new()
            else:
                raise ValueError("Retry policy must be 'default' or 'fallthrough'")
            if retry_policy_logging is True:
                cass_log_policy = cass_retry_policy_logging_new(cass_policy)
                error = cass_batch_set_retry_policy(self.cass_batch, cass_log_policy)
                raise_if_error(error)
                cass_retry_policy_free(cass_log_policy)
            else:
                error = cass_batch_set_retry_policy(self.cass_batch, cass_policy)
                raise_if_error(error)
            cass_retry_policy_free(cass_policy)

    def set_tracing(self, enabled: cass_bool_t):
        cdef CassError error
        if enabled is not None:
            error = cass_batch_set_tracing(self.cass_batch, enabled)
            raise_if_error(error)
            self.tracing_enabled = enabled

    def add_statement(self, Statement statement):
        cdef CassError error
        error = cass_batch_add_statement(self.cass_batch, statement.cass_statement)
        raise_if_error(error)

    def set_execution_profile(self, name: object) -> None:
        cdef CassError error
        if name is not None:
            error = cass_batch_set_execution_profile(self.cass_batch, name.encode())
            raise_if_error(error)


def create_batch_logged(timeout=None, execution_profile=None):
    cdef Batch batch
    batch = Batch.new_(CASS_BATCH_TYPE_LOGGED, timeout, execution_profile)
    return batch


def create_batch_unlogged(timeout=None, execution_profile=None):
    cdef Batch batch
    batch = Batch.new_(CASS_BATCH_TYPE_UNLOGGED, timeout, execution_profile)
    return batch


def create_batch_counter(timeout=None, execution_profile=None):
    cdef Batch batch
    batch = Batch.new_(CASS_BATCH_TYPE_COUNTER, timeout, execution_profile)
    return batch
