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

    def add_statement(self, Statement statement):
        cdef CassError error
        error = cass_batch_add_statement(self.cass_batch, statement.cass_statement)
        raise_if_error(error)

    def set_execution_profile(self, name: str) -> None:
        if name is None:
            return
        cdef CassError error = cass_batch_set_execution_profile(self.cass_batch, name.encode())
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
