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
        str log_level,
        object logging_callback,
        str whitelist_dc,
        str blacklist_dc,
        str whitelist_hosts,
        str blacklist_hosts,
    ):

        cdef CassProtocolVersion cass_protocol_version
        cdef str contact_points_csv
        cdef bytes contact_points_csv_b
        cdef CassError error
        cdef CassConsistency cass_consistency
        cdef int connect_timeout_ms = int(connect_timeout * 1000)
        cdef int request_timeout_ms = int(request_timeout * 1000)
        cdef int resolve_timeout_ms = int(resolve_timeout * 1000)

        logger = Logger(log_level, logging_callback=logging_callback)
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

        if whitelist_dc is not None:
            cass_cluster_set_whitelist_dc_filtering(self.cass_cluster, whitelist_dc.encode())
        if blacklist_dc is not None:
            cass_cluster_set_blacklist_dc_filtering(self.cass_cluster, blacklist_dc.encode())
        if whitelist_hosts is not None:
            cass_cluster_set_whitelist_filtering(self.cass_cluster, whitelist_hosts.encode())
        if blacklist_hosts is not None:
            cass_cluster_set_blacklist_filtering(self.cass_cluster, blacklist_hosts.encode())

    async def create_session(self, keyspace=None):
        session = Session(self, keyspace=keyspace)
        await session._connect()
        return session

    def create_execution_profile(
        self,
        name: str,
        request_timeout: int = None,
        consistency: "Consistency" = None,
        serial_consistency: "Consistency" = None,
        load_balance_round_robin: bool = False,
        load_balance_dc_aware: str = None,
        token_aware_routing: bool = True,
        token_aware_routing_shuffle_replicas: bool = True,
        latency_aware_routing: "LatencyAwareRoutingSettings" = None,
        whitelist_hosts: str = None,
        blacklist_hosts: str = None,
        whitelist_dc: str = None,
        blacklist_dc: str = None,
        retry_policy: str = None,
        retry_policy_logging: bool = False,
        speculative_execution_policy: "SpeculativeExecutionSettings" = None,
    ):
        cdef CassError error
        cdef CassRetryPolicy* cass_policy
        cdef CassRetryPolicy* cass_log_policy
        cdef CassExecProfile* profile = cass_execution_profile_new()

        if request_timeout is not None:
            error = cass_execution_profile_set_request_timeout(profile, <cass_uint64_t>request_timeout)
            raise_if_error(error)
        if consistency is not None:
            error = cass_execution_profile_set_consistency(profile, <CassConsistency>consistency.value)
            raise_if_error(error)
        if serial_consistency is not None:
            error = cass_execution_profile_set_serial_consistency(profile, <CassConsistency>serial_consistency.value)
            raise_if_error(error)
        if load_balance_round_robin is True:
            error = cass_execution_profile_set_load_balance_round_robin(profile)
            raise_if_error(error)
        if load_balance_dc_aware is not None:
            error = cass_execution_profile_set_load_balance_dc_aware(profile, load_balance_dc_aware.encode(), 0, cass_false)
            raise_if_error(error)
        if token_aware_routing is False:
            error = cass_execution_profile_set_token_aware_routing(profile, cass_false)
            raise_if_error(error)
        if token_aware_routing_shuffle_replicas is False:
            error = cass_execution_profile_set_token_aware_routing_shuffle_replicas(profile, cass_false)
            raise_if_error(error)
        if latency_aware_routing is not None:
            cass_execution_profile_set_latency_aware_routing(profile, cass_true)
            raise_if_error(error)
            error = cass_execution_profile_set_latency_aware_routing_settings(
                profile,
                <cass_double_t>latency_aware_routing.exclusion_threshold,
                <cass_uint64_t>latency_aware_routing.scale_ms,
                <cass_uint64_t>latency_aware_routing.retry_period_ms,
                <cass_uint64_t>latency_aware_routing.update_rate_ms,
                <cass_uint64_t>latency_aware_routing.min_measured
            )
            raise_if_error(error)
        if whitelist_hosts is not None:
            error = cass_execution_profile_set_whitelist_filtering(profile, whitelist_hosts.encode())
            raise_if_error(error)
        if blacklist_hosts is not None:
            error = cass_execution_profile_set_blacklist_filtering(profile, blacklist_hosts.encode())
            raise_if_error(error)
        if whitelist_dc is not None:
            error = cass_execution_profile_set_whitelist_dc_filtering(profile, whitelist_dc.encode())
            raise_if_error(error)
        if blacklist_dc is not None:
            error = cass_execution_profile_set_blacklist_dc_filtering(profile, blacklist_dc.encode())
            raise_if_error(error)
        if retry_policy is not None:
            if retry_policy == 'default':
                cass_policy = cass_retry_policy_default_new()
            elif retry_policy == 'fallthrough':
                cass_policy = cass_retry_policy_fallthrough_new()
            if retry_policy_logging is True:
                cass_log_policy = cass_retry_policy_logging_new(cass_policy)
                error = cass_execution_profile_set_retry_policy(profile, cass_log_policy)
                raise_if_error(error)
                cass_retry_policy_free(cass_log_policy)
            else:
                error = cass_execution_profile_set_retry_policy(profile, cass_policy)
                raise_if_error(error)
            cass_retry_policy_free(cass_policy)
        if speculative_execution_policy is not None:
            error = cass_execution_profile_set_constant_speculative_execution_policy(
                profile,
                <cass_int64_t>speculative_execution_policy.constant_delay_ms,
                <int>speculative_execution_policy.max_speculative_executions
            )
            raise_if_error(error)
        error = cass_cluster_set_execution_profile(self.cass_cluster, name.encode(), profile)
        raise_if_error(error)
        cass_execution_profile_free(profile)
