cdef class Batch:

    def __cinit__(self):
        self.cass_batch = NULL

    def __dealloc__(self):
        cass_batch_free(self.cass_batch)

    @staticmethod
    cdef Batch new_(CassBatchType type_):
        cdef Batch batch

        batch = Batch()
        batch.cass_batch = cass_batch_new(type_)
        return batch

    def add_statement(self, Statement statement):
        cdef CassError error

        error = cass_batch_add_statement(self.cass_batch, statement.cass_statement)
        if error != CASS_OK:
            raise CassException(error)


def create_batch_logged():
    cdef Batch batch
    batch = Batch.new_(CASS_BATCH_TYPE_LOGGED)
    return batch


def create_batch_unlogged():
    cdef Batch batch
    batch = Batch.new_(CASS_BATCH_TYPE_UNLOGGED)
    return batch
