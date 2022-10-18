cdef class Cluster:

    def __cinit__(self):
        # Starts the necessary machinary for bringing events
        # from the CPP driver to a Python Thread.
        # Is idempotent, can be called as many times as we want
        # but would be initalize only once.
        _initialize_posix_to_python_thread()
        self.ssl = NULL
        self.cass_cluster = NULL

    def __dealloc__(self):
        cass_cluster_free(self.cass_cluster)
        if self.ssl != NULL:
            cass_ssl_free(self.ssl)

    def __init__(
        self,
        list contact_points,
        int port,
        int protocol_version,
        object username,
        object password,
        float connect_timeout,
        float request_timeout,
        float resolve_timeout,
        object consistency,
        int core_connections_per_host,
        int local_port_range_min,
        int local_port_range_max,
        str application_name,
        str application_version,
        int num_threads_io,
        object ssl_enabled,
        object ssl_cert,
        object ssl_private_key,
        object ssl_private_key_password,
        object ssl_trusted_cert,
        object ssl_verify_flags,
        object log_level,
        object logging_callback
    ):

        cdef CassProtocolVersion cass_protocol_version
        cdef str contact_points_csv
        cdef bytes contact_points_csv_b
        cdef CassError error
        cdef CassConsistency cass_consistency
        cdef int connect_timeout_ms = int(connect_timeout * 1000)
        cdef int request_timeout_ms = int(request_timeout * 1000)
        cdef int resolve_timeout_ms = int(resolve_timeout * 1000)

        logger = Logger(logging_callback=logging_callback)
        Py_INCREF(logger)
        cass_log_set_callback(cb_log_message, <void*>logger)
        cass_log_set_level(log_level_from_str(log_level))

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

        self.cass_cluster = cass_cluster_new()

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

        if username is not None and password is not None:
            cass_cluster_set_credentials(self.cass_cluster, username.encode(), password.encode())
        elif username is not None or password is not None:
            raise ValueError("For using credentials both parameters (username and password) need to be set")

        cass_consistency = consistency.value
        error = cass_cluster_set_consistency(self.cass_cluster, cass_consistency)
        raise_if_error(error)

        error = cass_cluster_set_port(self.cass_cluster, port)
        raise_if_error(error)

        error = cass_cluster_set_core_connections_per_host(self.cass_cluster, core_connections_per_host)
        raise_if_error(error)

        error = cass_cluster_set_local_port_range(self.cass_cluster, local_port_range_min, local_port_range_max)
        raise_if_error(error)

        error = cass_cluster_set_num_threads_io(self.cass_cluster, num_threads_io)
        raise_if_error(error)

        cass_cluster_set_application_name(self.cass_cluster, application_name.encode())
        cass_cluster_set_application_version(self.cass_cluster, application_version.encode())

        if ssl_enabled:
            self.ssl = cass_ssl_new()

            if ssl_cert is not None:
                error = cass_ssl_set_cert(self.ssl, ssl_cert.encode())
                raise_if_error(error)

            if ssl_private_key is not None:
                error = cass_ssl_set_private_key(self.ssl, ssl_private_key.encode(), ssl_private_key_password.encode())
                raise_if_error(error)

            if ssl_verify_flags.value == CASS_SSL_VERIFY_PEER_IDENTITY_DNS:
                error = cass_cluster_set_use_hostname_resolution(self.cass_cluster, cass_true)
                raise_if_error(error)

            if ssl_trusted_cert is not None:
                error = cass_ssl_add_trusted_cert(self.ssl, ssl_trusted_cert.encode())
                raise_if_error(error)

            cass_ssl_set_verify_flags(self.ssl, ssl_verify_flags.value)
            cass_cluster_set_ssl(self.cass_cluster, self.ssl)

    async def create_session(self, keyspace=None):
        session = Session(self, keyspace=keyspace)
        await session._connect()
        return session
