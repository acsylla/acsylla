import asyncio

cdef class Session:

    def __cinit__(self, Cluster cluster):
        self.cass_cluster = cluster.cass_cluster
        self.cass_session = cass_session_new()
  
    def __dealloc__(self):
        cass_session_free(self.cass_session)

    def __init__(self, cass_cluster):
        self.loop = asyncio.get_running_loop()
        self.next_key = 0

    async def connect(self):
        cdef CallbackWrapper cb_wrapper
        cdef CassFuture* cass_future

        cb_wrapper = CallbackWrapper.new_(
            cass_session_connect_keyspace_n(self.cass_session, self.cass_cluster, "acsylla", 7),
            self.loop
        )

        await cb_wrapper.__await__()

    async def write(self):
        """ Just a POC wich tries to write a simple key and value """
        cdef CallbackWrapper cb_wrapper
        cdef CassStatement* cass_statement
        cdef CassFuture* cass_future

        self.next_key += 1

        statement = b"INSERT INTO test (id, value) values(" + str(self.next_key).encode() + b", 1)"

        cass_statement = cass_statement_new_n(
            statement,
            len(statement),
            0
        )

        cb_wrapper = CallbackWrapper.new_(
            cass_session_execute(self.cass_session, cass_statement),
            self.loop
        )

        await cb_wrapper.__await__()
