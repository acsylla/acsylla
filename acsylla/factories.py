from . import _cython
from .base import Batch
from .base import Cluster
from .base import Consistency
from .base import DseGssapiAuthenticator
from .base import DseGssapiAuthenticatorProxy
from .base import DsePlaintextAuthenticator
from .base import DsePlaintextAuthenticatorProxy
from .base import LatencyAwareRoutingSettings
from .base import ProtocolVersion
from .base import SpeculativeExecutionPolicy
from .base import SSLVerifyFlags
from .base import Statement
from .version import __version__
from typing import Callable
from typing import List
from typing import Optional
from typing import Union
from uuid import UUID


def create_cluster(
    contact_points: Union[str, List[str]] = None,
    port: Optional[int] = 9042,
    local_address: Optional[str] = None,
    local_port_range_min: Optional[int] = 49152,
    local_port_range_max: Optional[int] = 65535,
    username: Optional[str] = None,
    password: Optional[str] = None,
    connect_timeout: Optional[Union[int, float]] = 5.0,
    request_timeout: Optional[Union[int, float]] = 12.0,
    resolve_timeout: Optional[Union[int, float]] = 2.0,
    log_level: Optional[str] = "warn",
    logging_callback: Optional[Callable] = None,
    ssl_enabled: Optional[bool] = False,
    ssl_cert: Optional[str] = None,
    ssl_private_key: Optional[str] = None,
    ssl_private_key_password: Optional[str] = "",
    ssl_trusted_cert: Optional[str] = None,
    ssl_verify_flags: Optional[Union[str, SSLVerifyFlags]] = SSLVerifyFlags.PEER_CERT,
    protocol_version: Optional[Union[int, str, ProtocolVersion]] = None,
    use_beta_protocol_version: Optional[bool] = False,
    consistency: Optional[Union[str, Consistency]] = Consistency.LOCAL_ONE,
    serial_consistency: Optional[Union[str, Consistency]] = Consistency.ANY,
    num_threads_io: Optional[int] = 1,
    queue_size_io: Optional[int] = 8192,
    core_connections_per_host: Optional[int] = 1,
    constant_reconnect_delay_ms: Optional[int] = None,
    exponential_reconnect_base_delay_ms: Optional[int] = 2000,
    exponential_reconnect_max_delay_ms: Optional[int] = 60000,
    coalesce_delay_us: Optional[int] = 200,
    new_request_ratio: Optional[int] = 50,
    max_schema_wait_time_ms: Optional[int] = 10000,
    tracing_max_wait_time_ms: Optional[int] = 15,
    tracing_retry_wait_time_ms: Optional[int] = 3,
    tracing_consistency: Optional[Union[str, Consistency]] = Consistency.ONE,
    load_balance_round_robin: Optional[bool] = False,
    load_balance_dc_aware: Optional[str] = None,
    load_balance_rack_aware_dc: Optional[str] = None,
    load_balance_rack_aware_rack: Optional[str] = None,
    token_aware_routing: Optional[bool] = True,
    token_aware_routing_shuffle_replicas: Optional[bool] = True,
    latency_aware_routing: Optional[bool] = False,
    latency_aware_routing_settings: Optional[LatencyAwareRoutingSettings] = None,
    whitelist_dc: Optional[str] = None,
    blacklist_dc: Optional[str] = None,
    whitelist_hosts: Optional[str] = None,
    blacklist_hosts: Optional[str] = None,
    tcp_nodelay: Optional[bool] = True,
    tcp_keepalive_sec: Optional[int] = None,  # delay_secs Default: disabled
    timestamp_gen: Optional[str] = None,  # "server_side" or "monotonic"
    heartbeat_interval_sec: Optional[int] = 30,
    idle_timeout_sec: Optional[int] = 60,
    retry_policy: Optional[str] = None,  # "default" or "fallthrough"
    retry_policy_logging: Optional[bool] = False,
    use_schema: Optional[bool] = True,
    hostname_resolution: Optional[bool] = False,
    randomized_contact_points: Optional[bool] = True,
    speculative_execution_policy: Optional[SpeculativeExecutionPolicy] = None,
    max_reusable_write_objects: Optional[int] = None,  # Default: Max unsigned integer value
    prepare_on_all_hosts: Optional[bool] = True,
    no_compact: Optional[bool] = False,
    host_listener_callback: Optional[Callable] = None,  # Not implemented yet
    application_name: Optional[str] = "acsylla",
    application_version: Optional[str] = __version__,
    client_id: Optional[Union[str, UUID]] = None,
    monitor_reporting_interval_sec: Optional[int] = 300,
    cloud_secure_connection_bundle: Optional[str] = None,
    dse_gssapi_authenticator: Optional[DseGssapiAuthenticator] = None,
    dse_gssapi_authenticator_proxy: Optional[DseGssapiAuthenticatorProxy] = None,
    dse_plaintext_authenticator: Optional[DsePlaintextAuthenticator] = None,
    dse_plaintext_authenticator_proxy: Optional[DsePlaintextAuthenticatorProxy] = None,
) -> Cluster:
    """Instanciates a new cluster.

    Args:

        `contact_points`: Sets contact points. This MUST be set. White space is
            striped from the contact points.
            Examples: “127.0.0.1” “127.0.0.1,127.0.0.2”, “server1.domain.com”

        `port`: Sets the port.
            Default: 9042

        `local_address`: Sets the local address to bind when connecting to the
            cluster, if desired. IP address to bind, or empty string for no
            binding. Only numeric addresses are supported; no resolution is done.

        `local_port_range_min`: Sets the range of outgoing port numbers (ephemeral
            ports) to be used when establishing the shard-aware connections. This
            is applicable when the routing of connection to shard is based on the
            client-side port number.
            When application connects to multiple CassCluster-s it is advised
            to assign mutually non-overlapping port intervals to each. It is assumed
            that the supplied range is allowed by the OS (e.g. it fits inside
            /proc/sys/net/ipv4/ip_local_port_range on *nix systems)
            Default: 49152

        `local_port_range_max`: See `local_port_range_min`
            Default: 65535

        `username`: Sets credentials for plain text authentication.

        `password`: Sets credentials for plain text authentication.

        `connect_timeout`: Sets the timeout for connecting to a node.
            Default: 5 seconds

        `request_timeout`: Sets the timeout for waiting for a response from a node.
            Use 0 for no timeout.
            Default: 12 seconds

        resolve_timeout` Sets the timeout for waiting for DNS name resolution.
            Default: 2 seconds

        `log_level`: Sets the log level.
            Available levels: disabled, critical, error, warn, info, debug, trace
            Default: warn

        `logging_callback`: Sets a callback function to catch log messages.
            Default: An internal logger with "acsylla" name.
            logging.getLogger('acsylla')

            Example:
                def logging_callback(message: acsylla.LogMessage):
                    print(message)

        `ssl_enable`: Enable SSL connection
            Default: False

        `ssl_cert`: Set client-side certificate chain. This is used to authenticate
            the client on the server-side. This should contain the entire
            Certificate chain starting with the certificate itself

        `ssl_private_key`: Set client-side private key. This is used to authenticate
            the client on the server-side.

        `ssl_private_key_password`: Password for `ssl_private_key`

        `ssl_trusted_cert`: Adds a trusted certificate. This is used to verify the
            peer’s certificate.

        `ssl_verify_flags`: Sets verification performed on the peer’s certificate.

            * **NONE** - No verification is performed
            * **PEER_CERT** - Certificate is present and valid
            * **PEER_IDENTITY** - IP address matches the certificate’s common name or one
                of its subject alternative names. This implies the certificate is
                also present.
            * **PEER_IDENTITY_DNS** - Hostname matches the certificate’s common name or
                one of its subject alternative names. This implies the certificate
                is also present. Hostname resolution must also be enabled.

            Default: **PEER_CERT**

        `protocol_version`: Sets the protocol version. The driver will automatically
            downgrade to the lowest supported protocol version.
            Default: CASS_PROTOCOL_VERSION_V4 or CASS_PROTOCOL_VERSION_DSEV1 when
            using the DSE driver with DataStax Enterprise.

        `use_beta_protocol_version`: Use the newest beta protocol version. This
            currently enables the use of protocol version v5 (CASS_PROTOCOL_VERSION_V5)
            or DSEv2 (CASS_PROTOCOL_VERSION_DSEV2) when using the DSE driver with
            DataStax Enterprise.
            Default: false

        `consistency`: Sets default consistency level of statement.
            Default: LOCAL_ONE

        `serial_consistency`: Sets default serial consistency level of statement.
            Default: ANY

        `num_threads_io`: Sets the number of IO threads. This is the number of
            threads that will handle query requests.
            Default: 1

        `queue_size_io`: Sets the size of the fixed size queue that stores pending
            requests.
            Default: 8192

        `core_connections_per_host`: Sets the number of connections made to each
            server in each IO thread.
            Default: 1

        `constant_reconnect_delay_ms`: Configures the cluster to use a reconnection
            policy that waits a constant time between each reconnection attempt.
            Time in milliseconds to delay attempting a reconnection; 0 to perform
            a reconnection immediately.
            Default: Not set

        `exponential_reconnect_base_delay_ms`: The base delay (in milliseconds) to
            use for scheduling reconnection attempts.
            Configures the cluster to use a reconnection policy that waits
            exponentially longer between each reconnection attempt; however will
            maintain a constant delay once the maximum delay is reached.
            Note: A random amount of jitter (+/- 15%) will be added to the pure
            exponential delay value. This helps to prevent situations where
            multiple connections are in the reconnection process at exactly the
            same time. The jitter will never cause the delay to be less than the
            base delay, or more than the max delay.
            Default: 2000

        `exponential_reconnect_max_delay_ms`: The maximum delay to wait between two
            reconnection attempts. See `exponential_reconnect_max_delay_ms`
            Default: 60000

        `coalesce_delay_us`: Sets the amount of time, in microseconds, to wait for
            new requests to coalesce into a single system call. This should be set
            to a value around the latency SLA of your application’s requests while
            also considering the request’s roundtrip time. Larger values should be
            used for throughput bound workloads and lower values should be used for
            latency bound workloads.
            Default: 200 us

        `new_request_ratio`: Sets the ratio of time spent processing new requests
            versus handling the I/O and processing of outstanding requests. The
            range of this setting is 1 to 100, where larger values allocate more
            time to processing new requests and smaller values allocate more time
            to processing outstanding requests.
            Default: 50

        `max_schema_wait_time_ms`: Sets the maximum time to wait for schema
            agreement after a schema change is made (e.g. creating, altering,
            dropping a table/keyspace/view/index etc).
            Default: 10000 milliseconds

        `tracing_max_wait_time_ms`: Sets the maximum time to wait for tracing data
            to become available.
            Default: 15 milliseconds

        `tracing_retry_wait_time_ms`: Sets the amount of time to wait between
            attempts to check to see if tracing is available.
            Default: 3 milliseconds

        `tracing_consistency`: Sets the consistency level to use for checking to see
            if tracing data is available.
            Default: ONE

        `load_balance_round_robin`: Configures the cluster to use round-robin load
            balancing. The driver discovers all nodes in a cluster and cycles
            through them per request. All are considered ‘local’.

        `load_balance_dc_aware`: The primary data center to try first.
            Configures the cluster to use DC-aware load balancing. For each query,
            all live nodes in a primary ‘local’ DC are tried first, followed by any
            node from other DCs.
            Note: This is the default, and does not need to be called unless
            switching an existing from another policy or changing settings. Without
            further configuration, a default local_dc is chosen from the first
            connected contact point, and no remote hosts are considered in query
            plans. If relying on this mechanism, be sure to use only contact points
            from the local DC.

        `load_balance_rack_aware_dc`: DC for rack aware load balancing

        `load_balance_rack_aware_rack`: Rack for rack aware load balancing

        `token_aware_routing`: Configures the cluster to use token-aware request
            routing or not. This routing policy composes the base routing policy,
            routing requests first to replicas on nodes considered ‘local’ by the
            base load balancing policy.
            Important: Token-aware routing depends on keyspace metadata. For this
            reason enabling token-aware routing will also enable retrieving and
            updating keyspace schema metadata.
            Default: True (enabled).

        `token_aware_routing_shuffle_replicas`: Configures token-aware routing to
            randomly shuffle replicas. This can reduce the effectiveness of
            server-side caching, but it can better distribute load over replicas
            for a given partition key.
            Note: Token-aware routing `token_aware_routing` must be enabled for the
            setting to be  applicable.
            Default: True (enabled).

        `latency_aware_routing`: Configures the cluster to use latency-aware request
            routing or not. This routing policy is a top-level routing policy. It
            uses the base routing policy to determine locality (dc-aware) and/or
            placement (token-aware) before considering the latency.
            Default: False (disabled).

        `latency_aware_routing_settings`: Configures the settings for latency-aware
            request routing. Instance of :class:`acsylla.LatencyAwareRoutingSettings`

            Defaults:
                * **exclusion_threshold: 2.0** - Controls how much worse the
                  latency be compared to the average latency of the best
                  performing node before it penalized.

                * **scale_ms: 100** milliseconds - Controls the weight given to older
                  latencies when calculating the average latency of a node.
                  A bigger scale will give more weight to older latency measurements.

                * **retry_period_ms: 10,000** milliseconds - The amount of time a node is
                  penalized by the policy before being
                  given a second chance when the current
                  average latency exceeds the calculated
                  threshold (exclusion_threshold *
                  best_average_latency).

                * **update_rate_ms: 100** milliseconds The rate at which the
                  best average latency is recomputed.

                * **min_measured: 50** - The minimum number of measurements per-host
                  required to be considered by the policy

        `whitelist_hosts`: Sets whitelist hosts. The first call sets the whitelist
            hosts and any subsequent calls appends additional hosts. Passing an
            empty string will clear and disable the whitelist. White space is
            striped from the hosts.
            This policy filters requests to all other policies, only allowing
            requests to the hosts contained in the whitelist. Any host not in the
            whitelist will be ignored and a connection will not be established.
            This policy is useful for ensuring that the driver will only connect to
            a predefined set of hosts.
            Examples: “127.0.0.1” “127.0.0.1,127.0.0.2”

        `blacklist_hosts`: Sets blacklist hosts. The first call sets the blacklist
            hosts and any subsequent calls appends additional hosts. Passing an
            empty string will clear and disable the blacklist. White space is
            striped from the hosts.
            This policy filters requests to all other policies, only allowing
            requests to the hosts not contained in the blacklist. Any host in the
            blacklist will be ignored and a connection will not be established.
            This policy is useful for ensuring that the driver will not connect to
            a predefined set of hosts.
            Examples: “127.0.0.1” “127.0.0.1,127.0.0.2”

        `whitelist_dc`: Same as `whitelist_hosts`, but whitelist all hosts of a dc
            Examples: “dc1”, “dc1,dc2”

        `blacklist_dc`: Same as `blacklist_hosts`, but blacklist all hosts of a dc
            Examples: “dc1”, “dc1,dc2”

        `tcp_nodelay`: Enable/Disable Nagle’s algorithm on connections.
            Default: True

        `tcp_keepalive_sec`: Set keep-alive delay in seconds.
            Default: disabled

        `timestamp_gen`: "server_side" or "monotonic" Sets the timestamp generator
            used to assign timestamps to all requests unless overridden by setting
            the timestamp on a statement or a batch.
            Default: Monotonically increasing, client-side timestamp generator.

        `heartbeat_interval_sec`: Sets the amount of time between heartbeat messages
            and controls the amount of time the connection must be idle before
            sending heartbeat messages. This is useful for preventing intermediate
            network devices from dropping connections.
            Default: 30 seconds

        `idle_timeout_sec`: Sets the amount of time a connection is allowed to be
            without a successful heartbeat response before being terminated and
            scheduled for reconnection.
            Default: 60 seconds

        `retry_policy`: "default" or "fallthrough" Sets the retry policy used for
            all requests unless overridden by setting a retry policy on a statement
            or a batch.

            - **default**  This policy retries queries in the following cases:
                - On a read timeout, if enough replicas replied but data was not
                  received.
                - On a write timeout, if a timeout occurs while writing the
                  distributed batch log
                - On unavailable, it will move to the next host
                - In all other cases the error will be returned.
              This policy always uses the query’s original consistency level.
            - **fallthrough** This policy never retries or ignores a server-side
              failure. The error is always returned.
            Default: "**default**" This policy will retry on a read timeout if there
            was enough replicas, but no data present, on a write timeout if a
            logged batch request failed to write the batch log, and on a
            unavailable error it retries using a new host. In all other cases the
            default policy will return an error.

        `retry_policy_logging`: This policy logs the retry decision of its child
            policy. Logging is done using INFO level.
            Default: False

        `use_schema`: Enable/Disable retrieving and updating schema metadata. If
            disabled this is allows the driver to skip over retrieving and updating
            schema metadata. This can be useful for reducing the
            startup overhead of short-lived sessions.
            Default: True (enabled)

        `hostname_resolution`: Enable/Disable retrieving hostnames for IP addresses
            using reverse IP lookup. This is useful for authentication (Kerberos)
            or encryption (SSL) services that require a valid hostname for
            verification.
            Default: False (disabled)

        `randomized_contact_points`: Enable/Disable the randomization of the contact
            points list.
            Important: This setting should only be disabled for debugging or tests.
            Default: True (enabled)

        `speculative_execution_policy`: Enable constant speculative executions with
            the supplied settings `SpeculativeExecutionPolicy`.

        `max_reusable_write_objects`: Sets the maximum number of “pending write”
            objects that will be saved for re-use for marshalling new requests.
            These objects may hold on to a significant amount of memory and
            reducing the number of these objects may reduce memory usage of the
            application.
            The cost of reducing the value of this setting is potentially slower
            marshalling of requests prior to sending.
            Default: Max unsigned integer value

        `prepare_on_all_hosts`: Prepare statements on all available hosts.
            Default: True

        `no_compact`: Enable the NO_COMPACT startup option. This can help facilitate
            uninterrupted cluster upgrades where tables using COMPACT_STORAGE will
            operate in “compatibility mode” for BATCH, DELETE, SELECT, and UPDATE
            CQL operations.
            Default: False

        `host_listener_callback`: Sets a callback for handling host state changes in
            the cluster.
            Note: The callback is invoked only when state changes in the cluster
            are applicable to the configured load balancing policy(s).

        `application_name`: Set the application name. This is optional; however it
            provides the server with the application name that can aid in debugging
            issues with larger clusters where there are a lot of client (or
            application) connections.

        `application_version`: Set the application version. This is optional;
            however it provides the server with the application version that can
            aid in debugging issues with large clusters where there are a lot of
            client (or application) connections that may have different versions
            in use.

        `client_id`: Set the client id. This is optional; however it provides the
            server with the client ID that can aid in debugging issues with large
            clusters where there are a lot of client connections.
            Default: UUID v4 generated

        `monitor_reporting_interval_sec`: Sets the amount of time between monitor
            reporting event messages.
            Default: 300 seconds.

        `cloud_secure_connection_bundle`: Absolute path to DBaaS credentials file.
            Sets the secure connection bundle path for processing DBaaS credentials.
            This will pre-configure a cluster using the credentials format provided
            by the DBaaS cloud provider.
            Note: `contact_points` and `ssl_enable` should not used in conjunction
            with  `cloud_secure_connection_bundle`.
            Example: "/path/to/secure-connect-database_name.zip"
            Default: None

        `monitor_reporting_interval_sec`: Sets the amount of time between monitor
            reporting event messages.
            Default: 300 seconds.

        `dse_gssapi_authenticator`: Enables GSSAPI authentication for DSE clusters
            secured with the DseAuthenticator.
            Instance of `acsylla.DseGssapiAuthenticator`

        `dse_gssapi_authenticator_proxy`: Enables GSSAPI authentication with proxy
            authorization for DSE clusters secured with the DseAuthenticator.
            Instance of `acsylla.DseGssapiAuthenticatorProxy`

        `dse_plaintext_authenticator`: Enables plaintext authentication for DSE
            clusters secured with the DseAuthenticator.
            Instance of `acsylla.DsePlaintextAuthenticator`

        `dse_plaintext_authenticator_proxy`: Enables plaintext authentication with
            proxy authorization for DSE clusters secured with the DseAuthenticator.
            Instance of `acsylla.DsePlaintextAuthenticatorProxy`
    Returns:
        :class:`acsylla.Cluster` instance.
    """

    if isinstance(contact_points, list):
        contact_points = ",".join(contact_points)

    if protocol_version is not None:
        if isinstance(protocol_version, int):
            protocol_version = getattr(ProtocolVersion, f"V{protocol_version}", None)
        elif isinstance(protocol_version, str):
            protocol_version = getattr(ProtocolVersion, protocol_version.upper(), None)
        if isinstance(protocol_version, ProtocolVersion):
            protocol_version = protocol_version.value
        else:
            raise ValueError(f"Protocol version {protocol_version} invalid")

    if isinstance(consistency, str):
        consistency = getattr(Consistency, consistency.upper())
    if consistency is not None:
        consistency = consistency.value

    if isinstance(serial_consistency, str):
        serial_consistency = getattr(Consistency, serial_consistency.upper())
    if serial_consistency is not None:
        serial_consistency = serial_consistency.value

    if isinstance(tracing_consistency, str):
        tracing_consistency = getattr(Consistency, tracing_consistency.upper())
    if tracing_consistency is not None:
        tracing_consistency = tracing_consistency.value

    if isinstance(ssl_verify_flags, str):
        ssl_verify_flags = getattr(SSLVerifyFlags, ssl_verify_flags.upper())
    if ssl_verify_flags is not None:
        ssl_verify_flags = ssl_verify_flags.value

    if connect_timeout is not None:
        connect_timeout = int(connect_timeout * 1000)
    if request_timeout is not None:
        request_timeout = int(request_timeout * 1000)
    if resolve_timeout is not None:
        resolve_timeout = int(resolve_timeout * 1000)

    return _cython.cyacsylla.Cluster(
        contact_points=contact_points,
        port=port,
        local_address=local_address,
        local_port_range_min=local_port_range_min,
        local_port_range_max=local_port_range_max,
        username=username,
        password=password,
        connect_timeout=connect_timeout,
        request_timeout=request_timeout,
        resolve_timeout=resolve_timeout,
        log_level=log_level,
        logging_callback=logging_callback,
        ssl_enabled=ssl_enabled,
        ssl_cert=ssl_cert,
        ssl_private_key=ssl_private_key,
        ssl_private_key_password=ssl_private_key_password,
        ssl_trusted_cert=ssl_trusted_cert,
        ssl_verify_flags=ssl_verify_flags,
        protocol_version=protocol_version,
        use_beta_protocol_version=use_beta_protocol_version,
        consistency=consistency,
        serial_consistency=serial_consistency,
        num_threads_io=num_threads_io,
        queue_size_io=queue_size_io,
        core_connections_per_host=core_connections_per_host,
        constant_reconnect_delay_ms=constant_reconnect_delay_ms,
        exponential_reconnect_base_delay_ms=exponential_reconnect_base_delay_ms,
        exponential_reconnect_max_delay_ms=exponential_reconnect_max_delay_ms,
        coalesce_delay_us=coalesce_delay_us,
        new_request_ratio=new_request_ratio,
        max_schema_wait_time_ms=max_schema_wait_time_ms,
        tracing_max_wait_time_ms=tracing_max_wait_time_ms,
        tracing_retry_wait_time_ms=tracing_retry_wait_time_ms,
        tracing_consistency=tracing_consistency,
        load_balance_round_robin=load_balance_round_robin,
        load_balance_dc_aware=load_balance_dc_aware,
        load_balance_rack_aware_dc=load_balance_rack_aware_dc,
        load_balance_rack_aware_rack=load_balance_rack_aware_rack,
        token_aware_routing=token_aware_routing,
        token_aware_routing_shuffle_replicas=token_aware_routing_shuffle_replicas,
        latency_aware_routing=latency_aware_routing,
        latency_aware_routing_settings=latency_aware_routing_settings,
        whitelist_dc=whitelist_dc,
        blacklist_dc=blacklist_dc,
        whitelist_hosts=whitelist_hosts,
        blacklist_hosts=blacklist_hosts,
        tcp_nodelay=tcp_nodelay,
        tcp_keepalive_sec=tcp_keepalive_sec,
        timestamp_gen=timestamp_gen,
        heartbeat_interval_sec=heartbeat_interval_sec,
        idle_timeout_sec=idle_timeout_sec,
        retry_policy=retry_policy,
        retry_policy_logging=retry_policy_logging,
        use_schema=use_schema,
        hostname_resolution=hostname_resolution,
        randomized_contact_points=randomized_contact_points,
        speculative_execution_policy=speculative_execution_policy,
        max_reusable_write_objects=max_reusable_write_objects,
        prepare_on_all_hosts=prepare_on_all_hosts,
        no_compact=no_compact,
        host_listener_callback=host_listener_callback,
        application_name=application_name,
        application_version=application_version,
        client_id=client_id,
        monitor_reporting_interval_sec=monitor_reporting_interval_sec,
        cloud_secure_connection_bundle=cloud_secure_connection_bundle,
        dse_gssapi_authenticator=dse_gssapi_authenticator,
        dse_gssapi_authenticator_proxy=dse_gssapi_authenticator_proxy,
        dse_plaintext_authenticator=dse_plaintext_authenticator,
        dse_plaintext_authenticator_proxy=dse_plaintext_authenticator_proxy,
    )


def create_statement(
    statement: str,
    parameters: int = 0,
    page_size: Optional[int] = None,
    page_state: Optional[bytes] = None,
    timeout: Optional[float] = None,
    consistency: Optional[Consistency] = None,
    serial_consistency: Optional[Consistency] = None,
    execution_profile: Optional[str] = None,
    native_types: Optional[bool] = None,
) -> Statement:
    """
    Creates a new statement.

    Provide a raw `statement` and the number of `parameters` if there are, othewise will default to
    0.

    Pagination can be handled by providing a `page_size` for telling the maximum size of records
    fetched. The `page_state` will act as a cursor by returning the next results of a previous
    execution.

    If `timeout` is provided, this will override the request timeout provided during the cluster
    creation. Value expected is in seconds.

    If `consistency` is provided, this will override the consistency value provided during the cluster
    creation.

    `execution_profile` Assign the execution profile to the statement

    `native_types` Returns values as native types. Default: False
    """
    return _cython.cyacsylla.create_statement(
        statement,
        parameters=parameters,
        page_size=page_size,
        page_state=page_state,
        timeout=timeout,
        consistency=consistency,
        serial_consistency=serial_consistency,
        execution_profile=execution_profile,
        native_types=native_types,
    )


def create_batch_logged(timeout: Optional[float] = None, execution_profile: Optional[str] = None) -> Batch:
    """
    Creates a new batch logged.

    If `timeout` is provided, this will override the request timeout provided during the cluster
    creation. Value expected is in seconds.
    `execution_profile` Assign the execution profile to the statement
    """
    return _cython.cyacsylla.create_batch_logged(timeout, execution_profile)


def create_batch_unlogged(timeout: Optional[float] = None, execution_profile: Optional[str] = None) -> Batch:
    """
    Creates a new batch unlogged.

    If `timeout` is provided, this will override the request timeout provided during the cluster
    creation. Value expected is in seconds.
    `execution_profile` Assign the execution profile to the statement
    """
    return _cython.cyacsylla.create_batch_unlogged(timeout, execution_profile)


def create_batch_counter(timeout: Optional[float] = None, execution_profile: Optional[str] = None) -> Batch:
    """
    Creates a new batch counter.

    If `timeout` is provided, this will override the request timeout provided during the cluster
    creation. Value expected is in seconds.
    `execution_profile` Assign the execution profile to the statement
    """
    return _cython.cyacsylla.create_batch_counter(timeout, execution_profile)


def get_logger():
    """
    Returns the `Logger` instance
    """
    return _cython.cyacsylla.Logger.instance()
