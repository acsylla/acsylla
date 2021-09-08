cdef class Batch:

    def __cinit__(self):
        self.cass_batch = NULL

    def __dealloc__(self):
        cass_batch_free(self.cass_batch)

    @staticmethod
    cdef Batch new_(CassBatchType type_, object timeout):
        cdef CassError error
        cdef Batch batch
        cdef int timeout_ms

        batch = Batch()
        batch.cass_batch = cass_batch_new(type_)

        if timeout is not None:
            timeout_ms = int(timeout * 1000)
            error = cass_batch_set_request_timeout(batch.cass_batch, timeout_ms)
            if error != CASS_OK:
                raise CassException(error)

        return batch

    def add_statement(self, Statement statement):
        cdef CassError error

        error = cass_batch_add_statement(self.cass_batch, statement.cass_statement)
        if error != CASS_OK:
            raise CassException(error)


def create_batch_logged(timeout=None):
    cdef Batch batch
    batch = Batch.new_(CASS_BATCH_TYPE_LOGGED, timeout)
    return batch


def create_batch_unlogged(timeout=None):
    cdef Batch batch
    batch = Batch.new_(CASS_BATCH_TYPE_UNLOGGED, timeout)
    return batch


def create_batch_counter(timeout=None):
    cdef Batch batch
    batch = Batch.new_(CASS_BATCH_TYPE_COUNTER, timeout)
    return batch
