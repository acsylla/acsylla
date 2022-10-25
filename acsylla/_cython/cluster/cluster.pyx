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
        str contact_points=None, # const char * contact_points
        object port=None, # int port Default: 9042
        str local_address=None, # const char * name
        object local_port_range_min=None,
        object local_port_range_max=None,
        str log_level=None, # Default: CASS_LOG_WARN
        object logging_callback=None,
        object ssl_enabled=False, # bool Default: False
        str ssl_cert=None, # const char* cert
        str ssl_private_key=None, # const char * key,
        str ssl_private_key_password=None, # const char* password
        str ssl_trusted_cert=None, # const char * cert
        object ssl_verify_flags=None, # int flags Default: CASS_SSL_VERIFY_PEER_CERT
        object protocol_version=None, # int protocol_version Default: CASS_PROTOCOL_VERSION_V4
        object use_beta_protocol_version=False, # cass_bool_t enable Default: cass_false
        object consistency=None, # CassConsistency consistency Default: CASS_CONSISTENCY_LOCAL_ONE
        object serial_consistency=None, # CassConsistency consistency Default: CASS_CONSISTENCY_ANY
        object num_threads_io=None, # unsigned num_threads Default: 1
        object queue_size_io=None, # unsigned queue_size Default: 8192
        object core_connections_per_host=None, # unsigned num_connections Default: 1
        object constant_reconnect_delay_ms=None, # cass_uint64_t delay_ms
        object exponential_reconnect_base_delay_ms=None, # cass_uint64_t base_delay_ms Default: 2000 milliseconds base delay
        object exponential_reconnect_max_delay_ms=None, # cass_uint64_t max_delay_ms Default: 60000 milliseconds max delay
        object coalesce_delay_us=None, # cass_int64_t delay_us Default: 200 us
        object new_request_ratio=None, # cass_int32_t ratio Default: 50
        object connect_timeout=None, # unsigned timeout_ms Default: 5000 milliseconds
        object request_timeout=None, # unsigned timeout_ms Default: 12000 milliseconds
        object resolve_timeout=None, # unsigned timeout_ms Default: 2000 milliseconds
        object max_schema_wait_time_ms=None, # unsigned wait_time_ms Default: 10000 milliseconds
        object tracing_max_wait_time_ms=None, # max_wait_time_ms Default: 15 milliseconds
        object tracing_retry_wait_time_ms=None, # retry_wait_time_ms Default: 3 milliseconds
        object tracing_consistency=None, # Default: CASS_CONSISTENCY_ONE
        object username=None, # const char * username
        object password=None, # const char * password
        object load_balance_round_robin=False,
        str load_balance_dc_aware=None, # const char * local_dc
        object token_aware_routing=None, # cass_bool_t enabled Default: cass_true (enabled)
        object token_aware_routing_shuffle_replicas=None, # cass_bool_t enabled Default: cass_true (enabled)
        object latency_aware_routing=None, # cass_bool_t enabled Default: cass_false (disabled)
        object latency_aware_routing_settings=None, # instance of LatencyAwareRoutingSettings
                                            # Defaults:
                                            # cass_double_t exclusion_threshold: 2.0
                                            # cass_uint64_t scale_ms: 100 milliseconds
                                            # cass_uint64_t retry_period_ms: 10,000 milliseconds (10 seconds)
                                            # cass_uint64_t min_measured: 50
        str whitelist_dc=None, # const char * dcs
        str blacklist_dc=None, # const char * dcs
        str whitelist_hosts=None, # const char * hosts
        str blacklist_hosts=None, # const char * hosts
        object tcp_nodelay=None, # cass_bool_t enabled Default: cass_true
        object tcp_keepalive_sec=None, # unsigned delay_secs Default: disabled
        str timestamp_gen=None, # server_side or monotonic
        object heartbeat_interval_sec=None, # unsigned interval_secs Default: 30 seconds
        object idle_timeout_sec=None, # unsigned timeout_secs Default: 60 seconds
        str retry_policy=None, # default or fallthrough
        object retry_policy_logging=False, # logs the retry decision of its child policy
        object use_schema=None, # cass_bool_t enabled Default: cass_true (enabled)
        object hostname_resolution=None, # cass_bool_t enabled Default: cass_false (disabled)
        object randomized_contact_points=None, # cass_bool_t enabled Default: cass_true (enabled)
        object speculative_execution_policy=None, # instance of SpeculativeExecutionPolicy
                                                  # cass_int64_t constant_delay_ms
                                                  # int max_speculative_executions
        object max_reusable_write_objects=None, # unsigned num_objects Default: Max unsigned integer value
        object prepare_on_all_hosts=None, # cass_bool_t enabled Default: cass_true
        object no_compact=None, # cass_bool_t enabled Default: cass_false
        object host_listener_callback=None, # Not implemented yet
        str application_name=None, # const char * application_name
        str application_version=None, # const char * application_version
        object client_id=None, # CassUuid client_id Default: UUID v4 generated
        object monitor_reporting_interval_sec=None, # unsigned interval_secs Default: 300 seconds.
        object cloud_secure_connection_bundle=None,
        object dse_gssapi_authenticator=None, # Dict const char * service, const char * principal
        object dse_gssapi_authenticator_proxy=None, # Dict const char * service, const char * principal, const char * authorization_id
        object dse_plaintext_authenticator=None, # Dict const char * username, const char * password
        object dse_plaintext_authenticator_proxy=None # Dict const char * username, const char * password, const char * authorization_id
    ):

        cdef CassError error
        cdef CassUuid cass_client_id
        cdef CassRetryPolicy* cass_policy
        cdef CassRetryPolicy* cass_log_policy
        cdef CassTimestampGen* cass_timestamp_gen

        if not contact_points and not cloud_secure_connection_bundle:
            raise ValueError("Contact points can not be an empty value")

        logger = Logger(log_level, logging_callback=logging_callback)
        Py_INCREF(logger)
        cass_log_set_callback(cb_log_message, <void*>logger)
        if log_level is not None:
            cass_log_set_level(log_level_from_str(log_level))

        self.cass_cluster = cass_cluster_new()

        error = cass_cluster_set_contact_points(self.cass_cluster, contact_points.encode())
        raise_if_error(error)

        if port is not None:
            error = cass_cluster_set_port(self.cass_cluster, port)
            raise_if_error(error)

        if local_address is not None:
            error = cass_cluster_set_local_address(self.cass_cluster, local_address.encode())
            raise_if_error(error)

        if local_port_range_min is not None:
            if local_port_range_max is None:
                local_port_range_max = 65535
            error = cass_cluster_set_local_port_range(self.cass_cluster, local_port_range_min, local_port_range_max)
            raise_if_error(error)

        if protocol_version is not None:
            error = cass_cluster_set_protocol_version(self.cass_cluster, protocol_version)
            raise_if_error(error)

        if use_beta_protocol_version is True:
            error = cass_cluster_set_use_beta_protocol_version(self.cass_cluster, cass_true)
            raise_if_error(error)

        if connect_timeout is not None:
            cass_cluster_set_connect_timeout(self.cass_cluster, connect_timeout)

        if request_timeout is not None:
            cass_cluster_set_request_timeout(self.cass_cluster, request_timeout)

        if resolve_timeout is not None:
            cass_cluster_set_resolve_timeout(self.cass_cluster, resolve_timeout)

        if username is not None and password is not None:
            cass_cluster_set_credentials(self.cass_cluster, username.encode(), password.encode())
        elif username is not None or password is not None:
            raise ValueError("For using credentials both parameters (username and password) need to be set")

        if consistency is not None:
            error = cass_cluster_set_consistency(self.cass_cluster, consistency)
            raise_if_error(error)

        if serial_consistency is not None:
            error = cass_cluster_set_serial_consistency(self.cass_cluster, serial_consistency)
            raise_if_error(error)

        if hostname_resolution is not None:
            error = cass_cluster_set_use_hostname_resolution(self.cass_cluster, hostname_resolution)
            raise_if_error(error)

        if ssl_enabled:
            self.ssl = cass_ssl_new()
            if ssl_cert is not None:
                error = cass_ssl_set_cert(self.ssl, ssl_cert.encode())
                raise_if_error(error)
            if ssl_private_key is not None:
                error = cass_ssl_set_private_key(self.ssl, ssl_private_key.encode(), ssl_private_key_password.encode())
                raise_if_error(error)
            if ssl_verify_flags == CASS_SSL_VERIFY_PEER_IDENTITY_DNS:
                error = cass_cluster_set_use_hostname_resolution(self.cass_cluster, cass_true)
                raise_if_error(error)
            if ssl_trusted_cert is not None:
                error = cass_ssl_add_trusted_cert(self.ssl, ssl_trusted_cert.encode())
                raise_if_error(error)
            if ssl_verify_flags is not None:
                cass_ssl_set_verify_flags(self.ssl, ssl_verify_flags)
            cass_cluster_set_ssl(self.cass_cluster, self.ssl)

        if num_threads_io is not None:
            error = cass_cluster_set_num_threads_io(self.cass_cluster, num_threads_io)
            raise_if_error(error)

        if queue_size_io is not None:
            error = cass_cluster_set_queue_size_io(self.cass_cluster, queue_size_io)
            raise_if_error(error)

        if core_connections_per_host is not None:
            error = cass_cluster_set_core_connections_per_host(self.cass_cluster, core_connections_per_host)
            raise_if_error(error)

        if constant_reconnect_delay_ms is not None:
            cass_cluster_set_constant_reconnect(self.cass_cluster, constant_reconnect_delay_ms)

        if exponential_reconnect_base_delay_ms is not None:
            error = cass_cluster_set_exponential_reconnect(self.cass_cluster, exponential_reconnect_base_delay_ms, exponential_reconnect_max_delay_ms)

        if coalesce_delay_us is not None:
            error = cass_cluster_set_coalesce_delay(self.cass_cluster, coalesce_delay_us)

        if new_request_ratio is not None:
            error = cass_cluster_set_new_request_ratio(self.cass_cluster, new_request_ratio)

        if max_schema_wait_time_ms is not None:
            cass_cluster_set_max_schema_wait_time(self.cass_cluster, max_schema_wait_time_ms)

        if tracing_max_wait_time_ms is not None:
            cass_cluster_set_tracing_max_wait_time(self.cass_cluster, tracing_max_wait_time_ms)

        if tracing_retry_wait_time_ms is not None:
            cass_cluster_set_tracing_retry_wait_time(self.cass_cluster, tracing_retry_wait_time_ms)

        if tracing_consistency is not None:
            cass_cluster_set_tracing_consistency(self.cass_cluster, tracing_consistency)

        if load_balance_round_robin is not None:
            cass_cluster_set_load_balance_round_robin(self.cass_cluster)

        if load_balance_dc_aware is not None:
            error = cass_cluster_set_load_balance_dc_aware(self.cass_cluster, load_balance_dc_aware.encode(), 0, cass_false)
            raise_if_error(error)

        if token_aware_routing is not None:
            cass_cluster_set_token_aware_routing(self.cass_cluster, token_aware_routing)

        if token_aware_routing_shuffle_replicas is not None:
            cass_cluster_set_token_aware_routing_shuffle_replicas(self.cass_cluster, token_aware_routing_shuffle_replicas)

        if latency_aware_routing is not None:
            cass_cluster_set_latency_aware_routing(self.cass_cluster, latency_aware_routing)
            if latency_aware_routing_settings is not None:
                cass_cluster_set_latency_aware_routing_settings(
                    self.cass_cluster,
                    latency_aware_routing_settings.exclusion_threshold,
                    latency_aware_routing_settings.scale_ms,
                    latency_aware_routing_settings.retry_period_ms,
                    latency_aware_routing_settings.update_rate_ms,
                    latency_aware_routing_settings.min_measured

                )

        if application_name is not None:
            cass_cluster_set_application_name(self.cass_cluster, application_name.encode())

        if application_version is not None:
            cass_cluster_set_application_version(self.cass_cluster, application_version.encode())

        if whitelist_dc is not None:
            cass_cluster_set_whitelist_dc_filtering(self.cass_cluster, whitelist_dc.encode())

        if blacklist_dc is not None:
            cass_cluster_set_blacklist_dc_filtering(self.cass_cluster, blacklist_dc.encode())

        if whitelist_hosts is not None:
            cass_cluster_set_whitelist_filtering(self.cass_cluster, whitelist_hosts.encode())

        if blacklist_hosts is not None:
            cass_cluster_set_blacklist_filtering(self.cass_cluster, blacklist_hosts.encode())

        if tcp_nodelay is not None:
            cass_cluster_set_tcp_nodelay(self.cass_cluster, tcp_nodelay)

        if tcp_keepalive_sec is not None:
            cass_cluster_set_tcp_keepalive(self.cass_cluster, cass_true, tcp_keepalive_sec)

        if timestamp_gen is not None:
            if timestamp_gen == 'server_side':
                cass_timestamp_gen = cass_timestamp_gen_server_side_new()
            if timestamp_gen == 'monotonic':
                cass_timestamp_gen = cass_timestamp_gen_monotonic_new()
            cass_cluster_set_timestamp_gen(self.cass_cluster, cass_timestamp_gen)

        if heartbeat_interval_sec is not None:
            cass_cluster_set_connection_heartbeat_interval(self.cass_cluster, heartbeat_interval_sec)

        if idle_timeout_sec is not None:
            cass_cluster_set_connection_idle_timeout(self.cass_cluster, idle_timeout_sec)

        if retry_policy is not None:
            if retry_policy == 'default':
                cass_policy = cass_retry_policy_default_new()
            elif retry_policy == 'fallthrough':
                cass_policy = cass_retry_policy_fallthrough_new()
            else:
                raise ValueError("Retry policy must be 'default' or 'fallthrough'")
            if retry_policy_logging is True:
                cass_log_policy = cass_retry_policy_logging_new(cass_policy)
                cass_cluster_set_retry_policy(self.cass_cluster, cass_log_policy)
                cass_retry_policy_free(cass_log_policy)
            else:
                cass_cluster_set_retry_policy(self.cass_cluster, cass_policy)
            cass_retry_policy_free(cass_policy)

        if use_schema is not None:
            cass_cluster_set_use_schema(self.cass_cluster, use_schema)

        if randomized_contact_points is not None:
            error = cass_cluster_set_use_randomized_contact_points(self.cass_cluster, randomized_contact_points)
            raise_if_error(error)

        if speculative_execution_policy is not None:
            error = cass_cluster_set_constant_speculative_execution_policy(
                self.cass_cluster,
                speculative_execution_policy.constant_delay_ms,
                speculative_execution_policy.max_speculative_executions
            )
            raise_if_error(error)

        if max_reusable_write_objects is not None:
            error = cass_cluster_set_max_reusable_write_objects(self.cass_cluster, max_reusable_write_objects)
            raise_if_error(error)

        if prepare_on_all_hosts is not None:
            error = cass_cluster_set_prepare_on_all_hosts(self.cass_cluster, prepare_on_all_hosts)
            raise_if_error(error)

        if no_compact is not None:
            error = cass_cluster_set_no_compact(self.cass_cluster, no_compact)
            raise_if_error(error)

        if host_listener_callback is not None:
            raise NotImplementedError("host_listener_callback is not implemented yet")

        if client_id is not None:
            error = cass_uuid_from_string(client_id.encode(), &cass_client_id)
            raise_if_error(error)
            cass_cluster_set_client_id(self.cass_cluster, cass_client_id)

        if monitor_reporting_interval_sec is not None:
            cass_cluster_set_monitor_reporting_interval(self.cass_cluster, monitor_reporting_interval_sec)

        if cloud_secure_connection_bundle is not None:
            error = cass_cluster_set_cloud_secure_connection_bundle(self.cass_cluster, cloud_secure_connection_bundle.encode())
            raise_if_error(error)

        if dse_gssapi_authenticator is not None:
            error = cass_cluster_set_use_hostname_resolution(self.cass_cluster, cass_true)
            raise_if_error(error)
            error = cass_cluster_set_dse_gssapi_authenticator(
                self.cass_cluster,
                dse_gssapi_authenticator.service.encode(),
                dse_gssapi_authenticator.principal.encode()
            )
            raise_if_error(error)

        if dse_gssapi_authenticator_proxy is not None:
            error = cass_cluster_set_use_hostname_resolution(self.cass_cluster, cass_true)
            raise_if_error(error)
            error = cass_cluster_set_dse_gssapi_authenticator_proxy(
                self.cass_cluster,
                dse_gssapi_authenticator_proxy.service.encode(),
                dse_gssapi_authenticator_proxy.principal.encode(),
                dse_gssapi_authenticator_proxy.authorization_id.encode()
            )
            raise_if_error(error)

        if dse_plaintext_authenticator is not None:
            error = cass_cluster_set_dse_plaintext_authenticator(
                self.cass_cluster,
                dse_plaintext_authenticator.username.encode(),
                dse_gssapi_authenticator.password.encode()
            )
            raise_if_error(error)

        if dse_plaintext_authenticator_proxy is not None:
            error = cass_cluster_set_dse_plaintext_authenticator_proxy(
                self.cass_cluster,
                dse_plaintext_authenticator_proxy.username.encode(),
                dse_plaintext_authenticator_proxy.password.encode(),
                dse_plaintext_authenticator_proxy.authorization_id.encode()
            )
            raise_if_error(error)

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
        speculative_execution_policy: "SpeculativeExecutionPolicy" = None,
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
            else:
                raise ValueError("Retry policy must be 'default' or 'fallthrough'")
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
