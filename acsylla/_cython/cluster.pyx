cdef class Cluster:

    def __cinit__(self):
        self.cass_cluster = cass_cluster_new() 

    def __dealloc__(self):
        cass_cluster_free(self.cass_cluster)

    def __init__(self):
        cdef CassError error
        error = cass_cluster_set_contact_points(self.cass_cluster, "127.0.0.1")
        if error != CASS_OK:
            raise RuntimeError(error)

    async def create_session(self):
        session = Session(self)
        await session._connect()
        return
