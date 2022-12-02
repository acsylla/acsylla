cdef class Cluster:

    def __cinit__(self):
        # Starts the necessary machinary for bringing events
        # from the CPP driver to a Python Thread.
        # Is idempotent, can be called as many times as we want
        # but would be initalize only once.
        _initialize_posix_to_python_thread()
        self.ssl = NULL
        self.cass_cluster = NULL
        self.logger = Logger.instance()

    def __dealloc__(self):
        cass_cluster_free(self.cass_cluster)
        if self.ssl != NULL:
            cass_ssl_free(self.ssl)

    def __init__(
        self,
        str contact_points=None,
        object port=None,
        str local_address=None,
        object local_port_range_min=None,
        object local_port_range_max=None,
        str log_level=None,
        object logging_callback=None,
        object ssl_enabled=False,
        str ssl_cert=None,
        str ssl_private_key=None,
        str ssl_private_key_password=None,
        str ssl_trusted_cert=None,
        object ssl_verify_flags=None,
        object protocol_version=None,
        object use_beta_protocol_version=False,
        object consistency=None,
        object serial_consistency=None,
        object num_threads_io=None,
        object queue_size_io=None,
        object core_connections_per_host=None,
        object constant_reconnect_delay_ms=None,
        object exponential_reconnect_base_delay_ms=None,
        object exponential_reconnect_max_delay_ms=None,
        object coalesce_delay_us=None,
        object new_request_ratio=None,
        object connect_timeout=None,
        object request_timeout=None,
        object resolve_timeout=None,
        object max_schema_wait_time_ms=None,
        object tracing_max_wait_time_ms=None,
        object tracing_retry_wait_time_ms=None,
        object tracing_consistency=None,
        object username=None,
        object password=None,
        object load_balance_round_robin=False,
        str load_balance_dc_aware=None,
        object token_aware_routing=None,
        object token_aware_routing_shuffle_replicas=None,
        object latency_aware_routing=None,
        object latency_aware_routing_settings=None,
        str whitelist_dc=None,
        str blacklist_dc=None,
        str whitelist_hosts=None,
        str blacklist_hosts=None,
        object tcp_nodelay=None,
        object tcp_keepalive_sec=None,
        str timestamp_gen=None,
        object heartbeat_interval_sec=None,
        object idle_timeout_sec=None,
        str retry_policy=None,
        object retry_policy_logging=False,
        object use_schema=None,
        object hostname_resolution=None,
        object randomized_contact_points=None,
        object speculative_execution_policy=None,


        object max_reusable_write_objects=None,
        object prepare_on_all_hosts=None,
        object no_compact=None,
        object host_listener_callback=None,
        str application_name=None,
        str application_version=None,
        object client_id=None,
        object monitor_reporting_interval_sec=None,
        object cloud_secure_connection_bundle=None,
        object dse_gssapi_authenticator=None,
        object dse_gssapi_authenticator_proxy=None,
        object dse_plaintext_authenticator=None,
        object dse_plaintext_authenticator_proxy=None):

        self.cass_cluster = cass_cluster_new()

        self.set_contact_points(contact_points)
        self.set_port(port)
        self.set_local_address(local_address)
        self.set_local_port_range(local_port_range_min, local_port_range_max)
        self.set_log_level(log_level)
        self.set_logging_callback(logging_callback)
        self.set_protocol_version(protocol_version)
        self.set_use_beta_protocol_version(use_beta_protocol_version)
        self.set_connect_timeout(connect_timeout)
        self.set_request_timeout(request_timeout)
        self.set_resolve_timeout(resolve_timeout)
        self.set_credentials(username, password)
        self.set_consistency(consistency)
        self.set_serial_consistency(serial_consistency)
        self.set_hostname_resolution(hostname_resolution)
        self.set_ssl(ssl_enabled, ssl_cert, ssl_private_key, ssl_private_key_password, ssl_trusted_cert, ssl_verify_flags)
        self.set_num_threads_io(num_threads_io)
        self.set_queue_size_io(queue_size_io)
        self.set_core_connections_per_host(core_connections_per_host)
        self.set_constant_reconnect(constant_reconnect_delay_ms)
        self.set_exponential_reconnect(exponential_reconnect_base_delay_ms, exponential_reconnect_max_delay_ms)
        self.set_coalesce_delay(coalesce_delay_us)
        self.set_new_request_ratio(new_request_ratio)
        self.set_max_schema_wait_time(max_schema_wait_time_ms)
        self.set_tracing_max_wait_time(tracing_max_wait_time_ms)
        self.set_tracing_retry_wait_time(tracing_retry_wait_time_ms)
        self.set_tracing_consistency(tracing_consistency)
        self.set_load_balance_round_robin(load_balance_round_robin)
        self.set_load_balance_dc_aware(load_balance_dc_aware)
        self.set_token_aware_routing(token_aware_routing)
        self.set_token_aware_routing_shuffle_replicas(token_aware_routing_shuffle_replicas)
        self.set_latency_aware_routing(latency_aware_routing)
        if latency_aware_routing_settings is not None:
            self.set_latency_aware_routing_settings(
                latency_aware_routing_settings.exclusion_threshold,
                latency_aware_routing_settings.scale_ms,
                latency_aware_routing_settings.retry_period_ms,
                latency_aware_routing_settings.update_rate_ms,
                latency_aware_routing_settings.min_measured
            )
        self.set_application_name(application_name)
        self.set_application_version(application_version)
        self.set_whitelist_dc(whitelist_dc)
        self.set_blacklist_dc(blacklist_dc)
        self.set_whitelist_hosts(whitelist_hosts)
        self.set_blacklist_hosts(blacklist_hosts)
        self.set_tcp_nodelay(tcp_nodelay)
        if tcp_keepalive_sec is not None:
            self.set_tcp_keepalive(True, tcp_keepalive_sec)
        self.set_timestamp_gen(timestamp_gen)
        self.set_heartbeat_interval(heartbeat_interval_sec)
        self.set_idle_timeout(idle_timeout_sec)
        self.set_retry_policy(retry_policy, retry_policy_logging)
        self.set_use_schema(use_schema)
        self.set_randomized_contact_points(randomized_contact_points)
        if speculative_execution_policy is not None:
            self.set_speculative_execution_policy(
                speculative_execution_policy.constant_delay_ms,
                speculative_execution_policy.max_speculative_executions)
        self.set_max_reusable_write_objects(max_reusable_write_objects)
        self.set_prepare_on_all_hosts(prepare_on_all_hosts)
        self.set_no_compact(no_compact)
        self.set_host_listener_callback(host_listener_callback)
        self.set_client_id(client_id)
        self.set_monitor_reporting_interval(monitor_reporting_interval_sec)
        self.set_cloud_secure_connection_bundle(cloud_secure_connection_bundle)
        if dse_gssapi_authenticator is not None:
            self.set_dse_gssapi_authenticator(dse_gssapi_authenticator.service, dse_gssapi_authenticator.principal)
        if dse_gssapi_authenticator_proxy is not None:
            self.set_dse_gssapi_authenticator_proxy(
                dse_gssapi_authenticator_proxy.service,
                dse_gssapi_authenticator_proxy.principal,
                dse_gssapi_authenticator_proxy.authorization_id
            )
        if dse_plaintext_authenticator is not None:
            self.set_dse_plaintext_authenticator(
                dse_plaintext_authenticator.username.encode(),
                dse_gssapi_authenticator.password.encode()
            )
        if dse_plaintext_authenticator_proxy is not None:
            self.set_dse_plaintext_authenticator_proxy(
                dse_plaintext_authenticator_proxy.username.encode(),
                dse_plaintext_authenticator_proxy.password.encode(),
                dse_plaintext_authenticator_proxy.authorization_id.encode()
            )

    def set_contact_points(self, contact_points):
        if contact_points is not None:
            error = cass_cluster_set_contact_points(self.cass_cluster, contact_points.encode())
            raise_if_error(error)

    def set_port(self, port):
        if port is not None:
            error = cass_cluster_set_port(self.cass_cluster, port)
            raise_if_error(error)

    def set_local_address(self, local_address):
        if local_address is not None:
            error = cass_cluster_set_local_address(self.cass_cluster, local_address.encode())
            raise_if_error(error)

    def set_local_port_range(self, min, max):
        if min is not None and max is not None:
            error = cass_cluster_set_local_port_range(self.cass_cluster, min, max)
            raise_if_error(error)

    def set_credentials(self, username, password=''):
        if username is not None and password is not None:
            cass_cluster_set_credentials(self.cass_cluster, username.encode(), password.encode())
        elif username is not None or password is not None:
            raise ValueError("For using credentials both parameters (username and password) must be set")

    def set_connect_timeout(self, timeout_ms):
        if timeout_ms is not None:
            cass_cluster_set_connect_timeout(self.cass_cluster, timeout_ms)

    def set_request_timeout(self, timeout_ms):
        if timeout_ms is not None:
            cass_cluster_set_request_timeout(self.cass_cluster, timeout_ms)

    def set_resolve_timeout(self, timeout_ms):
        if timeout_ms is not None:
            cass_cluster_set_resolve_timeout(self.cass_cluster, timeout_ms)

    def set_log_level(self, level):
        if level is not None:
            self.logger.set_log_level(level)

    def set_logging_callback(self, callback):
        self.logger.set_logging_callback(callback)

    def set_ssl(self, enabled, cert=None, private_key=None, private_key_password='', trusted_cert=None, verify_flags=None):
        if enabled is True:
            self.ssl = cass_ssl_new()
            if cert is not None:
                error = cass_ssl_set_cert(self.ssl, cert.encode())
                raise_if_error(error)
            if private_key is not None:
                error = cass_ssl_set_private_key(self.ssl, private_key.encode(), private_key_password.encode())
                raise_if_error(error)
            if trusted_cert is not None:
                error = cass_ssl_add_trusted_cert(self.ssl, trusted_cert.encode())
                raise_if_error(error)
            if verify_flags is not None:
                if verify_flags == CASS_SSL_VERIFY_PEER_IDENTITY_DNS:
                    self.set_hostname_resolution(True)
                cass_ssl_set_verify_flags(self.ssl, verify_flags)
            cass_cluster_set_ssl(self.cass_cluster, self.ssl)

    def set_protocol_version(self, protocol_version):
        if protocol_version is not None:
            error = cass_cluster_set_protocol_version(self.cass_cluster, protocol_version)
            raise_if_error(error)

    def set_use_beta_protocol_version(self, enabled):
        if enabled is not None:
            error = cass_cluster_set_use_beta_protocol_version(self.cass_cluster, enabled)
            raise_if_error(error)

    def set_consistency(self, consistency):
        if consistency is not None:
            error = cass_cluster_set_consistency(self.cass_cluster, consistency)
            raise_if_error(error)

    def set_serial_consistency(self, consistency):
        if consistency is not None:
            error = cass_cluster_set_serial_consistency(self.cass_cluster, consistency)
            raise_if_error(error)

    def set_num_threads_io(self, num_threads):
        if num_threads is not None:
            error = cass_cluster_set_num_threads_io(self.cass_cluster, num_threads)
            raise_if_error(error)

    def set_queue_size_io(self, queue_size):
        if queue_size is not None:
            error = cass_cluster_set_queue_size_io(self.cass_cluster, queue_size)
            raise_if_error(error)

    def set_core_connections_per_host(self, num_connections):
        if num_connections is not None:
            error = cass_cluster_set_core_connections_per_host(self.cass_cluster, num_connections)
            raise_if_error(error)

    def set_constant_reconnect(self, delay_ms):
        if delay_ms is not None:
            cass_cluster_set_constant_reconnect(self.cass_cluster, delay_ms)

    def set_exponential_reconnect(self, base_delay_ms, max_delay_ms):
        if base_delay_ms is not None and max_delay_ms is not None:
            error = cass_cluster_set_exponential_reconnect(self.cass_cluster, base_delay_ms, max_delay_ms)
            raise_if_error(error)

    def set_coalesce_delay(self, delay_us):
        if delay_us is not None:
            error = cass_cluster_set_coalesce_delay(self.cass_cluster, delay_us)
            raise_if_error(error)

    def set_new_request_ratio(self, request_ratio):
        if request_ratio is not None:
            error = cass_cluster_set_new_request_ratio(self.cass_cluster, request_ratio)
            raise_if_error(error)

    def set_max_schema_wait_time(self, wait_time_ms):
        if wait_time_ms is not None:
            cass_cluster_set_max_schema_wait_time(self.cass_cluster, wait_time_ms)

    def set_tracing_max_wait_time(self, max_wait_time_ms):
        if max_wait_time_ms is not None:
            cass_cluster_set_tracing_max_wait_time(self.cass_cluster, max_wait_time_ms)

    def set_tracing_retry_wait_time(self, retry_wait_time_ms):
        if retry_wait_time_ms is not None:
            cass_cluster_set_tracing_retry_wait_time(self.cass_cluster, retry_wait_time_ms)

    def set_tracing_consistency(self, consistency):
        if consistency is not None:
            cass_cluster_set_tracing_consistency(self.cass_cluster, consistency)

    def set_load_balance_round_robin(self, enabled):
        if enabled is not True:
            cass_cluster_set_load_balance_round_robin(self.cass_cluster)

    def set_load_balance_dc_aware(self, dc):
        if dc is not None:
            error = cass_cluster_set_load_balance_dc_aware(self.cass_cluster, dc.encode(), 0, cass_false)
            raise_if_error(error)

    def set_token_aware_routing(self, enabled):
        if enabled is not None:
            cass_cluster_set_token_aware_routing(self.cass_cluster, enabled)

    def set_token_aware_routing_shuffle_replicas(self, enabled):
        if enabled is not None:
            cass_cluster_set_token_aware_routing_shuffle_replicas(self.cass_cluster, enabled)

    def set_latency_aware_routing(self, enabled):
        if enabled is not None:
            cass_cluster_set_latency_aware_routing(self.cass_cluster, enabled)

    def set_latency_aware_routing_settings(self,
                                           exclusion_threshold,
                                           scale_ms,
                                           retry_period_ms,
                                           update_rate_ms,
                                           min_measured):
        cass_cluster_set_latency_aware_routing_settings(
            self.cass_cluster,
            exclusion_threshold,
            scale_ms,
            retry_period_ms,
            update_rate_ms,
            min_measured)

    def set_whitelist_dc(self, dcs):
        if dcs is not None:
            cass_cluster_set_whitelist_dc_filtering(self.cass_cluster, dcs.encode())

    def set_blacklist_dc(self, dcs):
        if dcs is not None:
            cass_cluster_set_blacklist_dc_filtering(self.cass_cluster, dcs.encode())

    def set_whitelist_hosts(self, hosts):
        if hosts is not None:
            cass_cluster_set_whitelist_filtering(self.cass_cluster, hosts.encode())

    def set_blacklist_hosts(self, hosts):
        if hosts is not None:
            cass_cluster_set_blacklist_filtering(self.cass_cluster, hosts.encode())

    def set_tcp_nodelay(self, enabled):
        if enabled is not None:
            cass_cluster_set_tcp_nodelay(self.cass_cluster, enabled)

    def set_tcp_keepalive(self, enabled, delay_secs):
        if enabled is not None:
            cass_cluster_set_tcp_keepalive(self.cass_cluster, enabled, delay_secs)

    def set_timestamp_gen(self, timestamp_gen):
        if timestamp_gen is not None:
            if timestamp_gen == 'server_side':
                cass_timestamp_gen = cass_timestamp_gen_server_side_new()
            if timestamp_gen == 'monotonic':
                cass_timestamp_gen = cass_timestamp_gen_monotonic_new()
            else:
                raise ValueError("Timestamp gen must be 'server_side' or 'monotonic'")
            cass_cluster_set_timestamp_gen(self.cass_cluster, cass_timestamp_gen)

    def set_heartbeat_interval(self, interval_sec):
        if interval_sec is not None:
            cass_cluster_set_connection_heartbeat_interval(self.cass_cluster, interval_sec)

    def set_idle_timeout(self, timeout_sec):
        if timeout_sec is not None:
            cass_cluster_set_connection_idle_timeout(self.cass_cluster, timeout_sec)

    def set_retry_policy(self, policy, logging=False):
        if policy is not None:
            if policy == 'default':
                cass_policy = cass_retry_policy_default_new()
            elif policy == 'fallthrough':
                cass_policy = cass_retry_policy_fallthrough_new()
            else:
                raise ValueError("Retry policy must be 'default' or 'fallthrough'")
            if logging is True:
                cass_log_policy = cass_retry_policy_logging_new(cass_policy)
                cass_cluster_set_retry_policy(self.cass_cluster, cass_log_policy)
                cass_retry_policy_free(cass_log_policy)
            else:
                cass_cluster_set_retry_policy(self.cass_cluster, cass_policy)
            cass_retry_policy_free(cass_policy)

    def set_hostname_resolution(self, enabled):
        if enabled is not None:
            error = cass_cluster_set_use_hostname_resolution(self.cass_cluster, enabled)
            raise_if_error(error)

    def set_use_schema(self, enabled):
        if enabled is not None:
            cass_cluster_set_use_schema(self.cass_cluster, enabled)

    def set_randomized_contact_points(self, enabled):
        if enabled is not None:
            error = cass_cluster_set_use_randomized_contact_points(self.cass_cluster, enabled)
            raise_if_error(error)

    def set_speculative_execution_policy(self, constant_delay_ms, max_speculative_executions):
        if constant_delay_ms is not None:
            error = cass_cluster_set_constant_speculative_execution_policy(
                self.cass_cluster,
                constant_delay_ms,
                max_speculative_executions
            )
            raise_if_error(error)

    def set_no_speculative_execution_policy(self):
        error = cass_cluster_set_no_speculative_execution_policy(self.cass_cluster)
        raise_if_error(error)

    def set_max_reusable_write_objects(self, num_objects):
        if num_objects is not None:
            error = cass_cluster_set_max_reusable_write_objects(self.cass_cluster, num_objects)
            raise_if_error(error)

    def set_prepare_on_all_hosts(self, enabled):
        if enabled is not None:
            error = cass_cluster_set_prepare_on_all_hosts(self.cass_cluster, enabled)
            raise_if_error(error)

    def set_no_compact(self, enabled):
        if enabled is not None:
            error = cass_cluster_set_no_compact(self.cass_cluster, enabled)
            raise_if_error(error)

    def set_host_listener_callback(self, callback):
        if callback is not None:
            raise NotImplementedError("Host listener callback is not implemented yet")

    def set_application_name(self, name):
        if name is not None:
            cass_cluster_set_application_name(self.cass_cluster, name.encode())

    def set_application_version(self, version):
        if version is not None:
            cass_cluster_set_application_version(self.cass_cluster, version.encode())

    def set_client_id(self, client_id):
        cdef CassUuid cass_client_id
        if client_id is not None:
            error = cass_uuid_from_string(client_id.encode(), &cass_client_id)
            raise_if_error(error)
            cass_cluster_set_client_id(self.cass_cluster, cass_client_id)

    def set_monitor_reporting_interval(self, interval_sec):
        if interval_sec is not None:
            cass_cluster_set_monitor_reporting_interval(self.cass_cluster, interval_sec)

    def set_cloud_secure_connection_bundle(self, path):
        if path is not None:
            error = cass_cluster_set_cloud_secure_connection_bundle(self.cass_cluster, path.encode())
            raise_if_error(error)

    def set_dse_gssapi_authenticator(self, service, principal):
        if service is not None:
            error = cass_cluster_set_use_hostname_resolution(self.cass_cluster, cass_true)
            raise_if_error(error)
            error = cass_cluster_set_dse_gssapi_authenticator(self.cass_cluster, service.encode(), principal.encode())
            raise_if_error(error)

    def set_dse_gssapi_authenticator_proxy(self, service, principal, authorization_id):
        if service is not None:
            error = cass_cluster_set_use_hostname_resolution(self.cass_cluster, cass_true)
            raise_if_error(error)
            error = cass_cluster_set_dse_gssapi_authenticator_proxy(
                self.cass_cluster,
                service.encode(),
                principal.encode(),
                authorization_id.encode()
            )
            raise_if_error(error)

    def set_dse_plaintext_authenticator(self, username, password):
        if username is not None:
            error = cass_cluster_set_dse_plaintext_authenticator(self.cass_cluster, username.encode(), password.encode())
            raise_if_error(error)

    def set_dse_plaintext_authenticator_proxy(self, username, password, authorization_id):
        if username is not None:
            error = cass_cluster_set_dse_plaintext_authenticator_proxy(
                self.cass_cluster,
                username.encode(),
                password.encode(),
                authorization_id.encode()
            )
            raise_if_error(error)

    def get_logger(self):
        return self.logger

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
