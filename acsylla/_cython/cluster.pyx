cdef class Cluster:

    def __cinit__(self):
        # Starts the necessary machinary for bringing events
        # from the CPP driver to a Python Thread.
        # Is idempotent, can be called as many times as we want
        # but would be initalize only once.
        _initialize_posix_to_python_thread()

        self.cass_cluster = cass_cluster_new() 

    def __dealloc__(self):
        cass_cluster_free(self.cass_cluster)

    def __init__(self):
        cdef CassError error

        error = cass_cluster_set_contact_points_n(self.cass_cluster, "127.0.0.1", 9)
        if error != CASS_OK:
            raise RuntimeError(error)

        error = cass_cluster_set_protocol_version(self.cass_cluster, CASS_PROTOCOL_VERSION_V3)
        if error != CASS_OK:
            raise RuntimeError(error)

    async def create_session(self):
        session = Session(self)
        await session.connect()
        return session
