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

    def __init__(
        self,
        list contact_points,
        int protocol_version,
        float connect_timeout,
        float request_timeout,
        float resolve_timeout,
        object consistency):

        cdef CassProtocolVersion cass_protocol_version
        cdef str contact_points_csv
        cdef bytes contact_points_csv_b
        cdef CassError error
        cdef CassConsistency cass_consistency
        cdef int connect_timeout_ms = int(connect_timeout * 1000)
        cdef int request_timeout_ms = int(request_timeout * 1000)
        cdef int resolve_timeout_ms = int(resolve_timeout * 1000)

        if not contact_points:
            raise ValueError("Contact points can not be an empty list or a None value")

        if protocol_version == 1:
            cass_protocol_version = CASS_PROTOCOL_VERSION_V1
        elif protocol_version == 2:
            cass_protocol_version = CASS_PROTOCOL_VERSION_V2
        elif protocol_version == 3:
            cass_protocol_version = CASS_PROTOCOL_VERSION_V3
        elif protocol_version == 4:
            cass_protocol_version = CASS_PROTOCOL_VERSION_V4
        elif protocol_version == 5:
            cass_protocol_version = CASS_PROTOCOL_VERSION_V5
        else:
            raise ValueError(f"Protocol version {protocol_version} invalid")
 
        contact_points_csv = ",".join(contact_points)
        contact_points_csv_b = contact_points_csv.encode()
        error = cass_cluster_set_contact_points_n(
            self.cass_cluster,
            contact_points_csv_b,
            len(contact_points_csv_b)
        )
        raise_if_error(error)

        error = cass_cluster_set_protocol_version(self.cass_cluster, cass_protocol_version)
        raise_if_error(error)

        cass_cluster_set_connect_timeout(self.cass_cluster, connect_timeout_ms)
        cass_cluster_set_request_timeout(self.cass_cluster, request_timeout_ms)
        cass_cluster_set_resolve_timeout(self.cass_cluster, resolve_timeout_ms)


        cass_consistency = consistency.value
        error = cass_cluster_set_consistency(self.cass_cluster, cass_consistency)
        raise_if_error(error)

    async def create_session(self, keyspace=None):
        session = Session(self, keyspace=keyspace)
        await session._connect()
        return session
