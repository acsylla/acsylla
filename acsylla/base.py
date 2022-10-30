"""Abstract base classes, use them for documentation or for adding
types in your functions."""
from abc import ABCMeta
from abc import abstractmethod
from acsylla._cython import cyacsylla
from dataclasses import dataclass
from datetime import date
from datetime import datetime
from datetime import time
from datetime import timedelta
from decimal import Decimal
from enum import Enum
from ipaddress import IPv4Address
from ipaddress import IPv6Address
from typing import Callable
from typing import Dict
from typing import Iterable
from typing import List
from typing import Mapping
from typing import Optional
from typing import Sequence
from typing import Set
from typing import Union
from uuid import UUID

import json

SupportedType = Union[
    None,
    int,
    float,
    bool,
    str,
    bytes,
    list,
    set,
    dict,
    tuple,
    UUID,
    datetime,
    date,
    time,
    timedelta,
    IPv4Address,
    IPv6Address,
    Decimal,
]


@dataclass
class LatencyAwareRoutingSettings:
    """Configures the execution profile’s settings for latency-aware request
    routing.
       Note: Execution profiles use the cluster-level load balancing policy
        unless enabled. This setting is not applicable unless a load balancing
        policy is enabled on the execution profile.
    `exclusion_threshold` Controls how much worse the latency must be compared
        to the average latency of the best performing node before it penalized.
    `scale_ms` Controls the weight given to older latencies when calculating
        the average latency of a node. A bigger scale will give more weight to
        older latency measurements.
    `retry_period_ms` The amount of time a node is penalized by the policy
        before being given a second chance when the current average latency exceeds
        the calculated threshold (exclusion_threshold * best_average_latency).
    `update_rate_ms` The rate at which the best average latency is recomputed.
    `min_measured` The minimum number of measurements per-host required to be
        considered by the policy.
    """

    exclusion_threshold: float = 2.0
    scale_ms: int = 100
    retry_period_ms: int = 10_000
    update_rate_ms: int = 100
    min_measured: int = 50


@dataclass
class SpeculativeExecutionPolicy:
    """Settings for constant speculative execution policy"""

    constant_delay_ms: int
    max_speculative_executions: int


@dataclass
class DseGssapiAuthenticator:
    service: str
    principal: str


@dataclass
class DseGssapiAuthenticatorProxy:
    service: str
    principal: str
    authorization_id: str


@dataclass
class DsePlaintextAuthenticator:
    username: str
    password: str


@dataclass
class DsePlaintextAuthenticatorProxy:
    username: str
    password: str
    authorization_id: str


class Cluster(metaclass=ABCMeta):
    """Provides a Cluster instance class. Use the factory `create_cluster`
    for creating a new instance"""

    @abstractmethod
    def set_contact_points(self, contact_points: str) -> None:
        """Sets/Appends contact points. This MUST be set. The first call sets
            the contact points and any subsequent calls appends additional contact
            points. Passing an empty string will clear the contact points. White
            space is striped from the contact points.

        `contact_points` A comma delimited list of addresses or names. An empty
            string will clear the contact points. The string is copied into the
            cluster configuration;

        Examples: “127.0.0.1” “127.0.0.1,127.0.0.2”, “server1.domain.com”
        """

    @abstractmethod
    def set_port(self, port: int) -> None:
        """Sets the port."""

    @abstractmethod
    def set_local_address(self, local_address: str) -> None:
        """Sets the local address to bind when connecting to the cluster, if desired."""

    @abstractmethod
    def set_local_port_range(self, min: int, max: int) -> None:
        """ """

    @abstractmethod
    def set_credentials(self, username: str, password: str = "") -> None:
        """Sets credentials for plain text authentication."""

    @abstractmethod
    def set_connect_timeout(self, timeout_ms: int) -> None:
        """Sets the timeout for connecting to a node.
        Default: 5000 milliseconds

        `timeout_ms` Connect timeout in milliseconds
        """

    @abstractmethod
    def set_request_timeout(self, timeout_ms: int) -> None:
        """Sets the timeout for waiting for a response from a node.
        Default: 12000 milliseconds

        `timeout_ms` Request timeout in milliseconds. Use 0 for no timeout.
        """

    @abstractmethod
    def set_resolve_timeout(self, timeout_ms: int) -> None:
        """Sets the timeout for waiting for DNS name resolution.
        Default: 2000 milliseconds

        `timeout_ms` Request timeout in milliseconds
        """

    @abstractmethod
    def set_log_level(self, level: str) -> None:
        """ """

    @abstractmethod
    def set_logging_callback(self, callback: Callable) -> None:
        """ """

    @abstractmethod
    def set_ssl(
        self,
        enabled: bool,
        cert: str = None,
        private_key: str = None,
        private_key_password: str = "",
        trusted_cert: str = None,
        verify_flags: int = None,
    ) -> None:
        """Sets the SSL context and enables SSL."""

    @abstractmethod
    def set_protocol_version(self, protocol_version: int) -> None:
        """Sets the protocol version. The driver will automatically downgrade
        to the lowest supported protocol version.
        Default: CASS_PROTOCOL_VERSION_V4 or CASS_PROTOCOL_VERSION_DSEV1 when
        using the DSE driver with DataStax Enterprise.
        """

    @abstractmethod
    def set_use_beta_protocol_version(self, enabled: bool) -> None:
        """Use the newest beta protocol version. This currently enables the use
        of protocol version v5 (CASS_PROTOCOL_VERSION_V5) or DSEv2
        (CASS_PROTOCOL_VERSION_DSEV2) when using the DSE driver with DataStax
        Enterprise.
        Default: False
        """

    @abstractmethod
    def set_consistency(self, consistency: int) -> None:
        """Sets default consistency level of statement.
        Default: CASS_CONSISTENCY_LOCAL_ONE
        """

    @abstractmethod
    def set_serial_consistency(self, consistency: int) -> None:
        """Sets default serial consistency level of statement.
        Default: CASS_CONSISTENCY_ANY
        """

    @abstractmethod
    def set_num_threads_io(self, num_threads: int) -> None:
        """Sets the number of IO threads. This is the number of threads that
        will handle query requests.
        Default: 1
        """

    @abstractmethod
    def set_queue_size_io(self, queue_size: int) -> None:
        """Sets the size of the fixed size queue that stores pending requests.
        Default: 8192
        """

    @abstractmethod
    def set_core_connections_per_host(self, num_connections: int) -> None:
        """Sets the number of connections made to each server in each IO thread.
        Default: 1
        """

    @abstractmethod
    def set_constant_reconnect(self, delay_ms: int) -> None:
        """Configures the cluster to use a reconnection policy that waits a
        constant time between each reconnection attempt.

        `delay_ms` Time in milliseconds to delay attempting a reconnection;
            0 to perform a reconnection immediately.
        """

    @abstractmethod
    def set_exponential_reconnect(self, base_delay_ms: int, max_delay_ms: int) -> None:
        """Configures the cluster to use a reconnection policy that waits
            exponentially longer between each reconnection attempt; however
            will maintain a constant delay once the maximum delay is reached.
        Default:
            2000 milliseconds base delay
            60000 milliseconds max delay
        Note: A random amount of jitter (+/- 15%) will be added to the pure
            exponential delay value. This helps to prevent situations where
            multiple connections are in the reconnection process at exactly
            the same time. The jitter will never cause the delay to be less
            than the base delay, or more than the max delay.

        `base_delay_ms` The base delay (in milliseconds) to use for scheduling
            reconnection attempts.
        `max_delay_ms` The maximum delay to wait between two reconnection attempts.
        """

    @abstractmethod
    def set_coalesce_delay(self, delay_us: int) -> None:
        """Sets the amount of time, in microseconds, to wait for new requests
            to coalesce into a single system call. This should be set to a
            value around the latency SLA of your application’s requests while
            also considering the request’s roundtrip time. Larger values should
            be used for throughput bound workloads and lower values should be
            used for latency bound workloads.
        Default: 200 us
        """

    @abstractmethod
    def set_new_request_ratio(self, request_ratio: int) -> None:
        """Sets the ratio of time spent processing new requests versus handling
            the I/O and processing of outstanding requests. The range of this
            setting is 1 to 100, where larger values allocate more time to
            processing new requests and smaller values allocate more time to
            processing outstanding requests.
        Default: 50
        """

    @abstractmethod
    def set_max_schema_wait_time(self, wait_time_ms: int) -> None:
        """Sets the maximum time to wait for schema agreement after a schema
            change is made (e.g. creating, altering, dropping a
            table/keyspace/view/index etc).
        Default: 10000 milliseconds

        `wait_time_ms` Wait time in milliseconds
        """

    @abstractmethod
    def set_tracing_max_wait_time(self, max_wait_time_ms: int) -> None:
        """ """

    @abstractmethod
    def set_tracing_retry_wait_time(self, retry_wait_time_ms: int) -> None:
        """ """

    @abstractmethod
    def set_tracing_consistency(self, consistency: int) -> None:
        """ """

    @abstractmethod
    def set_load_balance_round_robin(self, enabled: bool) -> None:
        """Configures the cluster to use round-robin load balancing.
        The driver discovers all nodes in a cluster and cycles through them
            per request. All are considered ‘local’.
        """

    @abstractmethod
    def set_load_balance_dc_aware(self, dc: str) -> None:
        """Configures the cluster to use DC-aware load balancing. For each
            query, all live nodes in a primary ‘local’ DC are tried first,
            followed by any node from other DCs.
        Note: This is the default, and does not need to be called unless
            switching an existing from another policy or changing settings.
             Without further configuration, a default local_dc is chosen from
             the first connected contact point, and no remote hosts are
             considered in query plans. If relying on this mechanism, be sure
             to use only contact points from the local DC.

        `dc` The primary data center to try first
        """

    @abstractmethod
    def set_token_aware_routing(self, enabled: bool) -> None:
        """Configures the cluster to use token-aware request routing or not.
        Important: Token-aware routing depends on keyspace metadata. For this
            reason enabling token-aware routing will also enable retrieving and
            updating keyspace schema metadata.
        This routing policy composes the base routing policy, routing requests
            first to replicas on nodes considered ‘local’ by the base load
            balancing policy.
        Default: True (enabled).
        """

    @abstractmethod
    def set_token_aware_routing_shuffle_replicas(self, enabled: bool) -> None:
        """Configures token-aware routing to randomly shuffle replicas. This
            can reduce the effectiveness of server-side caching, but it can
            better distribute load over replicas for a given partition key.
        Note: Token-aware routing must be enabled for the setting to be applicable.
        Default: True (enabled)."""

    @abstractmethod
    def set_latency_aware_routing(self, enabled: bool) -> None:
        """Configures the cluster to use latency-aware request routing or not.
        This routing policy is a top-level routing policy. It uses the base
            routing policy to determine locality (dc-aware) and/or placement
            (token-aware) before considering the latency.
        Default: False (disabled).
        """

    @abstractmethod
    def set_latency_aware_routing_settings(
        self, exclusion_threshold: float, scale_ms: int, retry_period_ms: int, update_rate_ms: int, min_measured: int
    ) -> None:
        """Configures the settings for latency-aware request routing.
        Defaults:
            exclusion_threshold: 2.0
            scale_ms: 100 milliseconds
            retry_period_ms: 10,000 milliseconds (10 seconds)
            update_rate_ms: 100 milliseconds
            min_measured: 50

        `exclusion_threshold` Controls how much worse the latency must be
            compared to the average latency of the best performing node before
            it penalized.
        `scale_ms` Controls the weight given to older latencies when calculating
            the average latency of a node. A bigger scale will give more weight
            to older latency measurements.
        `retry_period_ms` The amount of time a node is penalized by the policy
            before being given a second chance when the current average latency
            exceeds the calculated threshold
            (exclusion_threshold * best_average_latency).
        `update_rate_ms` The rate at which the best average latency is
            recomputed.
        `min_measured` The minimum number of measurements per-host required to
            be considered by the policy.
        """

    @abstractmethod
    def set_whitelist_hosts(self, hosts: str) -> None:
        """Sets/Appends whitelist hosts. The first call sets the whitelist
                hosts and any subsequent calls appends additional hosts. Passing an
                empty string will clear and disable the whitelist. White space is
                striped from the hosts.
        This policy filters requests to all other policies, only allowing requests
            to the hosts contained in the whitelist. Any host not in the whitelist
            will be ignored and a connection will not be established. This policy
            is useful for ensuring that the driver will only connect to a
            predefined set of hosts.
        Examples: “127.0.0.1” “127.0.0.1,127.0.0.2”

        `hosts` A comma delimited list of addresses. An empty string will
            clear the whitelist hosts.
        """

    @abstractmethod
    def set_blacklist_hosts(self, hosts: str) -> None:
        """Sets/Appends blacklist hosts. The first call sets the blacklist
            hosts and any subsequent calls appends additional hosts. Passing an
            empty string will clear and disable the blacklist. White space is
            striped from the hosts.
        This policy filters requests to all other policies, only allowing
            requests to the hosts not contained in the blacklist. Any host in
            the blacklist will be ignored and a connection will not be
            established. This policy is useful for ensuring that the driver
            will not connect to a predefined set of hosts.
        Examples: “127.0.0.1” “127.0.0.1,127.0.0.2

        `hosts` A comma delimited list of addresses. An empty string will clear
            the blacklist hosts.
        ”"""

    @abstractmethod
    def set_whitelist_dc(self, dcs: str) -> None:
        """Same as `set_whitelist_hosts`, but whitelist all hosts of a dc
        Examples: “dc1”, “dc1,dc2

        `dcs` A comma delimited list of dcs. An empty string will clear the
            whitelist dcs.
        ”"""

    @abstractmethod
    def set_blacklist_dc(self, dcs: str) -> None:
        """Same as `set_blacklist_hosts`, but blacklist all hosts of a dc
        Examples: “dc1”, “dc1,dc2”

        `dcs` A comma delimited list of dcs. An empty string will clear the
            blacklist dcs.
        """

    @abstractmethod
    def set_tcp_nodelay(self, enabled: bool) -> None:
        """Enable/Disable Nagle’s algorithm on connections.
        Default: True"""

    @abstractmethod
    def set_tcp_keepalive(self, enabled: bool, delay_secs: int) -> None:
        """Enable/Disable TCP keep-alive
        Default: False (disabled).

        `enabled` True/False
        `delay_secs` The initial delay in seconds, ignored when enabled is False.
        """

    @abstractmethod
    def set_timestamp_gen(self, timestamp_gen: str) -> None:
        """Sets the timestamp generator used to assign timestamps to all
            requests unless overridden by setting the timestamp on a statement
            or a batch.
        Default: Monotonically increasing, client-side timestamp generator.

        `timestamp_gen` "server_side" or "monotonic"
        """

    @abstractmethod
    def set_heartbeat_interval(self, interval_sec: int) -> None:
        """Sets the amount of time between heartbeat messages and controls the
            amount of time the connection must be idle before sending heartbeat
            messages. This is useful for preventing intermediate network
            devices from dropping connections.
        Default: 30 seconds
        `interval_sec` Use 0 to disable heartbeat messages
        """

    @abstractmethod
    def set_idle_timeout(self, timeout_sec: int) -> None:
        """Sets the amount of time a connection is allowed to be without a
            successful heartbeat response before being terminated and scheduled
            for reconnection.
        Default: 60 seconds
        """

    @abstractmethod
    def set_retry_policy(self, policy: str, logging: bool = False) -> None:
        """Sets the retry policy used for all requests unless overridden by
            setting a retry policy on a statement or a batch.
        Default: "default" This policy will retry on a read timeout if there
            was enough replicas, but no data present, on a write timeout if a
            logged batch request failed to write the batch log, and on a
            unavailable error it retries using a new host. In all other cases
            the default policy will return an error.

        `policy` "default" or "fallthrough"
            "default"  This policy retries queries in the following cases:
                - On a read timeout, if enough replicas replied but data was not
                    received.
                - On a write timeout, if a timeout occurs while writing the
                    distributed batch log
                - On unavailable, it will move to the next host
                - In all other cases the error will be returned.
                This policy always uses the query’s original consistency level.
            "fallthrough" This policy never retries or ignores a server-side
                failure. The error is always returned.
        `logging` If set to True then this policy logs the retry decision of
            its child policy. Logging is done using INFO level.
        """

    @abstractmethod
    def set_hostname_resolution(self, enabled: bool) -> None:
        """Enable/Disable retrieving hostnames for IP addresses using reverse
            IP lookup.
        This is useful for authentication (Kerberos) or encryption (SSL)
            services that require a valid hostname for verification.
        Default: False (disabled).
        """

    @abstractmethod
    def set_use_schema(self, enabled: bool) -> None:
        """Enable/Disable retrieving and updating schema metadata. If disabled
            this is allows the driver to skip over retrieving and updating
            schema metadata and Session.get_metadata() will always return an
            empty object. This can be useful for reducing the startup overhead
            of short-lived sessions.
        Default: True (enabled)."""

    @abstractmethod
    def set_randomized_contact_points(self, enabled: bool) -> None:
        """Enable/Disable the randomization of the contact points list.
        Default: True (enabled).
        Important: This setting should only be disabled for debugging or tests.
        """

    @abstractmethod
    def set_speculative_execution_policy(self, constant_delay_ms: int, max_speculative_executions: int) -> None:
        """Enable constant speculative executions with the supplied settings."""

    @abstractmethod
    def set_no_speculative_execution_policy(self) -> None:
        """Disable speculative executions
        Default: This is the default speculative execution policy.
        """

    @abstractmethod
    def set_max_reusable_write_objects(self, num_objects: int) -> None:
        """Sets the maximum number of “pending write” objects that will be
            saved for re-use for marshalling new requests. These objects may
            hold on to a significant amount of memory and reducing the number
            of these objects may reduce memory usage of the application.
        The cost of reducing the value of this setting is potentially slower
            marshalling of requests prior to sending.
        Default: Max unsigned integer value
        """

    @abstractmethod
    def set_prepare_on_all_hosts(self, enabled: bool) -> None:
        """Prepare statements on all available hosts.
        Default: True
        """

    @abstractmethod
    def set_no_compact(self, enabled: bool) -> None:
        """Enable the NO_COMPACT startup option.
        This can help facilitate uninterrupted cluster upgrades where tables
            using COMPACT_STORAGE will operate in “compatibility mode” for
            BATCH, DELETE, SELECT, and UPDATE CQL operations.
        Default: False
        """

    @abstractmethod
    def set_host_listener_callback(self, callback: Callable) -> None:
        """Sets a callback for handling host state changes in the cluster.
        Note: The callback is invoked only when state changes in the cluster
        are applicable to the configured load balancing policy(s)."""

    @abstractmethod
    def set_application_name(self, name: str) -> None:
        """Set the application name.
        This is optional; however it provides the server with the application
            name that can aid in debugging issues with larger clusters where
            there are a lot of client (or application) connections.
        """

    @abstractmethod
    def set_application_version(self, version: str) -> None:
        """Set the application version.
        This is optional; however it provides the server with the application
            version that can aid in debugging issues with large clusters where
            there are a lot of client (or application) connections that may
            have different versions in use.
        """

    @abstractmethod
    def set_client_id(self, client_id: str) -> None:
        """Set the client id.
        This is optional; however it provides the server with the client ID
            that can aid in debugging issues with large clusters where there
            are a lot of client connections.
        Default: UUID v4 generated

        `client_id` UUIDv4 string.
        """

    @abstractmethod
    def set_monitor_reporting_interval(self, interval_sec: int) -> None:
        """Sets the amount of time between monitor reporting event messages.
        Default: 300 seconds.
        """

    @abstractmethod
    def set_cloud_secure_connection_bundle(self, path: str) -> None:
        """Sets the secure connection bundle path for processing DBaaS
            credentials.
        This will pre-configure a cluster using the credentials format provided
            by the DBaaS cloud provider.
        Note: `contact_points` and `ssl` should not used in conjunction
            with  `cloud_secure_connection_bundle`.
        Example: "/path/to/secure-connect-database_name.zip"
        Default: None

        `path` Absolute path to DBaaS credentials file.
        """

    @abstractmethod
    def set_dse_gssapi_authenticator(self, service: str, principal: str) -> None:
        """Enables GSSAPI authentication for DSE clusters secured with the
        DseAuthenticator.
        """

    @abstractmethod
    def set_dse_gssapi_authenticator_proxy(self, service: str, principal: str, authorization_id: str) -> None:
        """Enables GSSAPI authentication with proxy authorization for DSE
        clusters secured with the DseAuthenticator.
        """

    @abstractmethod
    def set_dse_plaintext_authenticator(self, username: str, password: str) -> None:
        """Enables plaintext authentication for DSE clusters secured with the
        DseAuthenticator.
        """

    @abstractmethod
    def set_dse_plaintext_authenticator_proxy(self, username: str, password: str, authorization_id: str) -> None:
        """Enables plaintext authentication with proxy authorization for DSE
        clusters secured with the DseAuthenticator.
        """

    @abstractmethod
    async def create_session(self, keyspace: Optional[str] = None) -> "Session":
        """Returns a new session by using the Cluster configuration.

        If Keyspace is provided, the session will be bound to the keyspace and
        any statment, unlesss says the opposite, will be using that keyspace.

        The coroutine will try to make a connection to the cluster hosts.
        """

    @abstractmethod
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
    ) -> None:
        """Execution profiles provide a mechanism to group together a set of
        configuration options and reuse them across different query executions.

        Execution profiles are being introduced to help deal with the exploding
        number of configuration options, especially as the database platform
        evolves into more complex workloads. The number of options being
        introduced with the execution profiles is limited and may be expanded
        based on feedback from the community.

        `request_timeout` Sets the timeout waiting for a response from a node.
            Default: Disabled (uses the cluster request timeout)
        `consistency` Sets the consistency level.
            Default: Disabled (uses the default consistency)
        `serial_consistency` Sets the serial consistency level.
            Default: Disabled (uses the default serial consistency)
        `load_balance_round_robin` Configures the execution profile to use
            round-robin load balancing. The driver discovers all nodes in a
            cluster and cycles through  them per request. All are considered
            ‘local’.
           Note: Profile-based load balancing policy is disabled by default;
            cluster load balancing policy is used when profile does not
            contain a policy.
        `load_balance_dc_aware` Configures the execution profile to use
            DC-aware load balancing. For each query, all live nodes in a
            primary ‘local’ DC are tried first, followed by any node from other
            DCs.
           Note: Profile-based load balancing policy is disabled by default;
            cluster load balancing policy is used when profile does not contain
            a policy.
           Example: "datacenter1"
        `token_aware_routing` Configures the execution profile to use
            token-aware request routing or not.
           Important: Token-aware routing depends on keyspace metadata. For
            this reason enabling token-aware routing will also enable
            retrieving and updating keyspace schema metadata.
           Default: true (enabled).
            This routing policy composes the base routing policy, routing
            requests first to replicas on nodes considered ‘local’ by the base
            load balancing policy.
           Note: Execution profiles use the cluster-level load balancing policy
            unless enabled. This setting is not applicable unless a load
            balancing policy is enabled on the execution profile.
        `token_aware_routing_shuffle_replicas` Configures the execution
            profile’s token-aware routing to randomly shuffle replicas. This
            can reduce the effectiveness of server-side caching, but it can
            better distribute load over replicas for a given partition key.
           Note: Token-aware routing must be enabled and a load balancing
            policy must be enabled on the execution profile for the setting to
            be applicable.
           Default: true (enabled).
        `latency_aware_routing` Configures the execution profile to use
            latency-aware request routing or not.
           Note: Execution profiles use the cluster-level load balancing policy
           unless enabled. This setting is not applicable unless a load
           balancing policy is enabled on the execution profile.
          Default: Disable. For enable use `LatencyAwareRoutingSettings`
           This routing policy is a top-level routing policy. It uses the base
           routing policy to determine locality (dc-aware) and/or placement
           (token-aware) before considering the latency.
        `whitelist_hosts` Sets whitelist hosts for the execution profile.
            This policy filters requests to all other policies, only allowing
            requests to the hosts contained in the whitelist. Any host not in
            the whitelist will be ignored and a connection will not be
            established. This policy is useful for ensuring that the driver
            will only connect to a predefined set of hosts.
           Examples: “127.0.0.1” “127.0.0.1,127.0.0.2”
           Note: Execution profiles use the cluster-level load balancing policy
            unless enabled. This setting is not applicable unless a load
            balancing policy is enabled on the execution profile.
        `blacklist_hosts` Sets blacklist hosts for the execution profile.
            The first call sets the blacklist hosts and any subsequent calls
            appends additional hosts. Passing an empty string will clear and
            disable the blacklist. White space is striped from the hosts.
            This policy filters requests to all other policies, only allowing
            requests to the hosts not contained in the blacklist. Any host in
            the blacklist will be ignored and a connection will not be
            established. This policy is useful for ensuring that the driver
            will not connect to a predefined set of hosts.
           Examples: “127.0.0.1” “127.0.0.1,127.0.0.2”
           Note: Execution profiles use the cluster-level load balancing policy
            unless enabled. This setting is not applicable unless a load
            balancing policy is enabled on the execution profile.
        `whitelist_dc` Same as `whitelist_hosts`, but whitelist
            all hosts of a DC.
           Examples: “dc1”, “dc1,dc2”
        `blacklist_dc` Same as `blacklist_hosts`, but blacklist
            all hosts of a dc.
           Examples: “dc1”, “dc1,dc2”
        `retry_policy` Sets the execution profile’s retry policy.
           Note: Profile-based retry policy is disabled by default; cluster
            retry policy is used when profile does not contain a policy unless
            the retry policy was explicitly set on the batch/statement request.
           Values:
            `default` This policy retries queries in the following cases:
                - On a read timeout, if enough replicas replied but data was
                    not received.
                - On a write timeout, if a timeout occurs while writing the
                    distributed batch log
                - On unavailable, it will move to the next host
                In all other cases the error will be returned.
                This policy always uses the query’s original consistency level.
            `fallthrough` This policy never retries or ignores a server-side
                failure. The error is always returned.
        `retry_policy_logging` If `retry_policy` is set then add logging using
            log level INFO for selected policy.
        `constant_speculative_execution_policy` Enable constant speculative
            executions with the supplied settings `SpeculativeExecutionPolicy`
            for the execution profile.
           Note: Profile-based speculative execution policy is disabled by
            default; cluster speculative execution policy is used when profile
            does not contain a policy.
        """


class Session(metaclass=ABCMeta):
    """Provides a Session instance class. Use the the
    `Cluster.create_session` coroutine for creating a new instance"""

    @abstractmethod
    async def set_keyspace(self, keyspace: str) -> "Result":
        """Sets the keyspace for session"""

    @abstractmethod
    def get_client_id(self) -> str:
        """Get the client id."""

    @abstractmethod
    def get_metadata(self) -> "Metadata":
        """Gets a snapshot of this session’s schema metadata."""

    @abstractmethod
    async def close(self) -> None:
        """Closes a session.

        After calling this method no more executions will be allowed
        raising the proper excetion if this is the case.
        """

    @abstractmethod
    async def execute(self, statement: "Statement") -> "Result":
        """Executes an statement and returns the result."""

    @abstractmethod
    async def create_prepared(self, statement: str, timeout: Optional[float] = None) -> "PreparedStatement":
        """Prepares an statement.

        By providing a `timeout` all requests built by the prepared statement will use it,
        otherwise timeout provided during the Cluster instantantation will be used. Value expected is seconds.
        """

    @abstractmethod
    async def execute_batch(self, batch: "Batch") -> "Result":
        """Executes a batch of statements."""

    @abstractmethod
    def metrics(self) -> "SessionMetrics":
        """Returns the metrics related to the session."""

    @abstractmethod
    def speculative_execution_metrics(self) -> "SpeculativeExecutionMetrics":
        """Returns speculative execution performance metrics gathered by the driver."""


class Metadata(metaclass=ABCMeta):
    """Provides a Metadata instance class for retrieving metadata from cluster."""

    @abstractmethod
    def get_version(self) -> tuple:
        """Gets the version of the connected cluster."""

    @abstractmethod
    def get_snapshot_version(self) -> int:
        """Gets the version of the schema metadata snapshot."""

    @abstractmethod
    def get_keyspaces(self) -> List[str]:
        """Returns a list of all keyspaces names from cluster."""

    @abstractmethod
    def get_keyspace_meta(self, name) -> "KeyspaceMeta":
        """Returns metadata for given keyspace."""

    @abstractmethod
    def get_user_types(self, keyspace) -> List[str]:
        """Returns a list of user defined types (UDT) names for given keyspace name."""

    @abstractmethod
    def get_user_type_meta(self, keyspace, name) -> "UserTypeMeta":
        """Returns metadata for user defined types (UDT) for given keyspace name and type name."""

    @abstractmethod
    def get_user_types_meta(self, keyspace) -> List["UserTypeMeta"]:
        """Returns a list of user defined types (UDT) metadata for given keyspace name."""

    @abstractmethod
    def get_functions(self, keyspace) -> List[str]:
        """Returns a list of functions names for the given keyspace name."""

    @abstractmethod
    def get_function_meta(self, keyspace, name) -> "FunctionMeta":
        """Returns metadata for function for given keyspace name and function name."""

    @abstractmethod
    def get_functions_meta(self, keyspace) -> List["FunctionMeta"]:
        """Returns a list of functions metadata for given keyspace name."""

    @abstractmethod
    def get_aggregates(self, keyspace) -> List[str]:
        """Returns a list of aggregates names for the given keyspace name."""

    @abstractmethod
    def get_aggregate_meta(self, keyspace, name) -> "AggregateMeta":
        """Returns metadata for aggregate for given keyspace name and aggregate name."""

    @abstractmethod
    def get_aggregates_meta(self, keyspace) -> List["AggregateMeta"]:
        """Returns a list of aggregates metadata for given keyspace name."""

    @abstractmethod
    def get_tables(self, keyspace) -> List[str]:
        """Returns a list of tables names for the given keyspace name."""

    @abstractmethod
    def get_table_meta(self, keyspace, name) -> "TableMeta":
        """Returns metadata for table for given keyspace name and table name."""

    @abstractmethod
    def get_tables_meta(self, keyspace) -> List["TableMeta"]:
        """Returns a list of tables metadata for given keyspace name."""

    @abstractmethod
    def get_indexes(self, keyspace) -> List[str]:
        """Returns a list of indexes names for the given keyspace name."""

    @abstractmethod
    def get_index_meta(self, keyspace, name) -> "IndexMeta":
        """Returns metadata for index for given keyspace name and index name."""

    @abstractmethod
    def get_indexes_meta(self, keyspace) -> List["IndexMeta"]:
        """Returns a list of indexes metadata for given keyspace name."""

    @abstractmethod
    def get_materialized_views(self, keyspace) -> List[str]:
        """Returns a list of materialized views names for the given keyspace name."""

    @abstractmethod
    def get_materialized_view_meta(self, keyspace, name) -> "MaterializedViewMeta":
        """Returns metadata for materialized view for given keyspace name and materialized view name."""

    @abstractmethod
    def get_materialized_views_meta(self, keyspace) -> List["MaterializedViewMeta"]:
        """Returns a list of materialized views metadata for given keyspace name."""


class Statement(metaclass=ABCMeta):
    """Provides a Statement instance class. Use the the
    `create_statement` factory for creating a new instance"""

    @abstractmethod
    def add_key_index(self, index: int) -> None:
        """Adds a key index specifier to this a statement. When using
        token-aware routing, this can be used to tell the driver which
        parameters within a non-prepared, parameterized statement are part of
        the partition key.

        Use consecutive calls for composite partition keys.

        This is not necessary for prepared statements, as the key parameters
        are determined in the metadata processed in the prepare phase."""

    @abstractmethod
    def reset_parameters(self, count: int) -> None:
        """Clear and/or resize the statement’s parameters."""

    @abstractmethod
    def bind(self, index: int, value: SupportedType) -> None:
        """Binds the value to a specific index parameter.

        If an invalid type is used for a prepared statement this will raise
        immediately an error. If a none prepared exception is used error will
        be raised later during the execution statement.

        If an invalid index is used this will raise immediately an error
        """

    @abstractmethod
    def bind_by_name(self, name: str, value: SupportedType) -> None:
        """Binds the the value to a specific parameter by name.

        If an invalid type is used for this will raise immediately an error. If an
        invalid name is used this will raise immediately an error
        """

    @abstractmethod
    def bind_list(self, values: Sequence[SupportedType]) -> None:
        """Binds the values into all parameters from left to right.

        For types supported and errors that this function might raise take
        a look at the `Statement.bind` function.
        """

    @abstractmethod
    def bind_dict(self, values: Mapping[str, SupportedType]) -> None:
        """Binds the values into all parameter names. Names are the keys
        of the mapping provided.

        For types supported and errors that this function might raise take
        a look at the `Statement.bind_dict` function.

        Note: This method are only allowed for statements created using
        prepared statements
        """

    @abstractmethod
    def set_page_size(self, page_size: int) -> None:
        """Sets the statement's page size."""

    @abstractmethod
    def set_page_state(self, page_state: bytes) -> None:
        """Sets the statement's paging state. This can be used to get the next
        page of data in a multi-page query.

        Warning: The paging state should not be exposed to or come from
        untrusted environments. The paging state could be spoofed and potentially
        used to gain access to other data.
        """

    @abstractmethod
    def set_timeout(self, timeout: float) -> None:
        """Sets the statement's timeout in seconds for waiting for a response from a node.
        Default: Disabled (use the cluster-level request timeout)"""

    @abstractmethod
    def set_consistency(self, timeout: float) -> None:
        """Sets the statement’s consistency level.
        Default: LOCAL_ONE"""

    @abstractmethod
    def set_serial_consistency(self, timeout: float) -> None:
        """Sets the statement’s serial consistency level.
        Default: Not set"""

    @abstractmethod
    def set_timestamp(self, timestamp: int) -> None:
        """Sets the statement’s timestamp."""

    @abstractmethod
    def set_is_idempotent(self, is_idempotent: bool) -> None:
        """Sets whether the statement is idempotent. Idempotent statements are
        able to be automatically retried after timeouts/errors and can be
        speculatively executed."""

    @abstractmethod
    def set_retry_policy(self, retry_policy: str, retry_policy_logging: bool = False) -> None:
        """Sets the statement’s retry policy.

        `retry_policy` "default" or "fallthrough" Sets the retry policy used for
            all requests in batch.
            "default"  This policy retries queries in the following cases:
                - On a read timeout, if enough replicas replied but data was not
                    received.
                - On a write timeout, if a timeout occurs while writing the
                    distributed batch log
                - On unavailable, it will move to the next host
                - In all other cases the error will be returned.
                This policy always uses the query’s original consistency level.
            "fallthrough" This policy never retries or ignores a server-side
                failure. The error is always returned.
            Default: "default" This policy will retry on a read timeout if there
            was enough replicas, but no data present, on a write timeout if a
            logged batch request failed to write the batch log, and on a
            unavailable error it retries using a new host. In all other cases the
            default policy will return an error.

        `retry_policy_logging` This policy logs the retry decision of its child
            policy. Logging is done using INFO level.
            Default: False
        """

    @abstractmethod
    def set_tracing(self, enabled: bool = None) -> None:
        """Sets whether the statement should use tracing."""

    @abstractmethod
    def set_host(self, host: str, port: int = 9042) -> None:
        """Sets a specific host that should run the query.

        In general, this should not be used, but it can be useful in the
        following situations:
            To query node-local tables such as system and virtual tables.
            To apply a sequence of schema changes where it makes sense for all
            the changes to be applied on a single node.
        """

    @abstractmethod
    def set_execution_profile(self, name: str) -> None:
        """Sets the execution profile to execute the statement with.
        Note: Empty string will clear execution profile from statement
        """


class PreparedStatement(metaclass=ABCMeta):
    """Provides a PreparedStatement instance class. Use the
    `session.create_prepared()` coroutine for creating a new instance"""

    @abstractmethod
    def bind(
        self,
        page_size: Optional[int] = None,
        page_state: Optional[bytes] = None,
        execution_profile: Optional[str] = None,
    ) -> Statement:
        """Returns a new statment using the prepared."""

    @abstractmethod
    def set_execution_profile(self, statement: Statement, name: str) -> None:
        """Sets the execution profile to execute the statement with.
        Note: Empty string will clear execution profile from statement
        """


class Batch(metaclass=ABCMeta):
    """Provides a Batch instance class. Use the
    `create_batch_logged()`, `create_batch_unlogged()` and create_batch_counter()
    factories for creating a new instance."""

    @abstractmethod
    def set_consistency(self, consistency: int) -> None:
        """Sets the batch’s consistency level"""

    @abstractmethod
    def set_serial_consistency(self, consistency: int) -> None:
        """Sets the batch’s serial consistency level."""

    @abstractmethod
    def set_timestamp(self, timestamp: int) -> None:
        """Sets the batch’s timestamp."""

    @abstractmethod
    def set_request_timeout(self, timeout_ms: int) -> None:
        """Sets the batch’s timeout for waiting for a response from a node.
        Default: Disabled (use the cluster-level request timeout)
        """

    @abstractmethod
    def set_is_idempotent(self, is_idempotent) -> None:
        """Sets whether the statements in a batch are idempotent. Idempotent
        batches are able to be automatically retried after timeouts/errors and
        can be speculatively executed."""

    @abstractmethod
    def set_retry_policy(self, retry_policy: str, retry_policy_logging: bool = False) -> None:
        """Sets the batch’s retry policy.

        `retry_policy` "default" or "fallthrough" Sets the retry policy used for
            all requests in batch.
            "default"  This policy retries queries in the following cases:
                - On a read timeout, if enough replicas replied but data was not
                    received.
                - On a write timeout, if a timeout occurs while writing the
                    distributed batch log
                - On unavailable, it will move to the next host
                - In all other cases the error will be returned.
                This policy always uses the query’s original consistency level.
            "fallthrough" This policy never retries or ignores a server-side
                failure. The error is always returned.
            Default: "default" This policy will retry on a read timeout if there
            was enough replicas, but no data present, on a write timeout if a
            logged batch request failed to write the batch log, and on a
            unavailable error it retries using a new host. In all other cases the
            default policy will return an error.

        `retry_policy_logging` This policy logs the retry decision of its child
            policy. Logging is done using INFO level.
            Default: False
        """

    @abstractmethod
    def set_tracing(self, enabled: bool) -> None:
        """Sets whether the batch should use tracing."""

    @abstractmethod
    def add_statement(self, statement: Statement) -> None:
        """Adds a new statement to the batch."""

    @abstractmethod
    def set_execution_profile(self, name: str) -> None:
        """Sets the execution profile to execute the statement with.
        Note: Empty string will clear execution profile from statement
        """


class Result(metaclass=ABCMeta):
    """Provides a result instance class. Use the
    `session.execute()` coroutine for getting the result
    from a query"""

    @abstractmethod
    def count(self) -> int:
        """Returns the total rows of the result"""

    @abstractmethod
    def column_count(self) -> int:
        """Returns the total columns returned"""

    @abstractmethod
    def columns_names(self) -> List[str]:
        """Returns the columns names"""

    @abstractmethod
    def first(self) -> Optional["Row"]:
        """Return the first result, if there is no row
        returns None.
        """

    @abstractmethod
    def all(self) -> Iterable["Row"]:
        """Return the all rows using of a result, using an
        iterator.

        If there is no rows iterator returns no rows.
        """

    @abstractmethod
    def has_more_pages(self) -> bool:
        """Returns true if there is still pages to be fetched"""

    @abstractmethod
    def page_state(self) -> bytes:
        """Returns a token with the page state for continuing fetching
        new results.

        Before calling this method you must first checks if there are more
        results using the `has_more_pages` function, and if there are use the
        token returned by this function as an argument of the factories for creating
        an statement for returning the next page.
        """


class Row(metaclass=ABCMeta):
    """Provides access to a row of a `Result`"""

    @abstractmethod
    def as_dict(self) -> dict:
        """Returns the row as dict."""

    @abstractmethod
    def as_list(self) -> list:
        """Returns the row as list."""

    @abstractmethod
    def as_tuple(self) -> tuple:
        """Returns the row as tuple."""

    @abstractmethod
    def as_named_tuple(self) -> tuple:
        """Returns the row as named tuple."""

    @abstractmethod
    def column_count(self) -> int:
        """Returns column count."""

    @abstractmethod
    def column_value(self, name: str) -> SupportedType:
        """Returns the row column value called by `name`.

        Raises a `CassException` derived exception if the column can not be found

        Type is inferred by using the Cassandra driver
        and converted, if supported, to a Python type or one
        of the extended types provided by Acsylla.
        """

    @abstractmethod
    def column_value_by_index(self, index) -> SupportedType:
        """Returns the column value by `column index`.
        Raises an exception if the column can not be found"""


@dataclass
class SessionMetrics:
    """Provides basic metrics for the Session."""

    # requests time statistics in microseconds.
    requests_min: int
    requests_max: int
    requests_mean: int
    requests_stddev: int
    requests_median: int
    requests_percentile_75th: int
    requests_percentile_95th: int
    requests_percentile_98th: int
    requests_percentile_99th: int
    requests_percentile_999th: int

    # requests rate, requests per second
    requests_mean_rate: float
    requests_one_minute_rate: float
    requests_five_minute_rate: float
    requests_fifteen_minute_rate: float

    # Total connections available
    stats_total_connections: int

    # counters of timeouts at connection and
    # request level
    errors_connection_timeouts: int
    errors_request_timeouts: int


@dataclass
class SpeculativeExecutionMetrics:
    """Provides speculative execution metrics.
    `min` Minimum in microseconds
    `max` Maximum in microseconds
    `mean` Mean in microseconds
    `stddev` Standard deviation in microseconds
    `median` Median in microseconds
    `percentile_75th` 75th percentile in microseconds
    `percentile_95th` 95th percentile in microseconds
    `percentile_98th` 98th percentile in microseconds
    `percentile_99th` 99the percentile in microseconds
    `percentile_999th` 99.9th percentile in microseconds
    `count` The number of aborted speculative retries
    `percentage` Fraction of requests that are aborted speculative retries
    """

    min: int  # Minimum in microseconds
    max: int  # Maximum in microseconds
    mean: int  # Mean in microseconds
    stddev: int  # Standard deviation in microseconds
    median: int  # Median in microseconds
    percentile_75th: int  # 75th percentile in microseconds
    percentile_95th: int  # 95th percentile in microseconds
    percentile_98th: int  # 98th percentile in microseconds
    percentile_99th: int  # 99the percentile in microseconds
    percentile_999th: int  # 99.9th percentile in microseconds
    count: int  # The number of aborted speculative retries
    percentage: float  # Fraction of requests that are aborted speculative retries


class ProtocolVersion(Enum):
    V1 = cyacsylla.ProtocolVersion.V1
    V2 = cyacsylla.ProtocolVersion.V2
    V3 = cyacsylla.ProtocolVersion.V3
    V4 = cyacsylla.ProtocolVersion.V4
    V5 = cyacsylla.ProtocolVersion.V5
    DSEV1 = cyacsylla.ProtocolVersion.DSEV1
    DSEV2 = cyacsylla.ProtocolVersion.DSEV2


class Consistency(Enum):
    ANY = cyacsylla.Consistency.ANY
    ONE = cyacsylla.Consistency.ONE
    TWO = cyacsylla.Consistency.TWO
    THREE = cyacsylla.Consistency.THREE
    QUORUM = cyacsylla.Consistency.QUORUM
    ALL = cyacsylla.Consistency.ALL
    LOCAL_QUORUM = cyacsylla.Consistency.LOCAL_QUORUM
    EACH_QUORUM = cyacsylla.Consistency.EACH_QUORUM
    SERIAL = cyacsylla.Consistency.SERIAL
    LOCAL_SERIAL = cyacsylla.Consistency.LOCAL_SERIAL
    LOCAL_ONE = cyacsylla.Consistency.LOCAL_ONE


class SSLVerifyFlags(Enum):
    """Sets verification performed on the peer’s certificate.

    NONE - No verification is performed
    PEER_CERT - Certificate is present and valid
    PEER_IDENTITY - IP address matches the certificate’s common name or one of its
      subject alternative names. This implies the certificate is also present.
    PEER_IDENTITY_DNS - Hostname matches the certificate’s common name or
      one of its subject alternative names. This implies the certificate is
      also present. Hostname resolution must also be enabled.
    """

    NONE = cyacsylla.SSLVerifyFlags.NONE
    PEER_CERT = cyacsylla.SSLVerifyFlags.PEER_CERT
    PEER_IDENTITY = cyacsylla.SSLVerifyFlags.PEER_IDENTITY
    PEER_IDENTITY_DNS = cyacsylla.SSLVerifyFlags.PEER_IDENTITY_DNS


@dataclass
class LogMessage:
    """Log message"""

    time_ms: int
    log_level: str
    file: str
    line: int
    function: str
    message: str


@dataclass
class NestedTypeMeta:
    """User type field metadata."""

    type: str
    is_frozen: bool


@dataclass
class UserTypeFieldMeta:
    """User type field metadata."""

    name: str
    type: str
    is_frozen: bool
    nested_types: List[NestedTypeMeta]


@dataclass
class UserTypeMeta:
    """User type metadata."""

    keyspace: str
    name: str
    is_frozen: bool
    fields: List[UserTypeFieldMeta]

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate this type.
        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        user type name in CREATE statement.
        For example CREATE TYPE keyspace_name.type_name... if with_keyspace is
        set to False, statement will be CREATE TYPE type_name.."""

        keyspace = f"{self.keyspace}."
        if with_keyspace is False:
            keyspace = ""
        query = f"CREATE TYPE {keyspace}{self.name} ("
        for field in self.fields:
            nested = ""
            if field.nested_types:
                nested = []
                for el in field.nested_types:
                    if el.is_frozen:
                        nested.append(f"frozen<{el.type}>")
                    else:
                        nested.append(f"{el.type}")
                nested = ", ".join(nested)

            if field.is_frozen:
                if field.nested_types:
                    query += f"\n\t{field.name} frozen<{field.type}<{nested}>>,"
                else:
                    query += f"\n\t{field.name} frozen<{field.type}>,"
            else:
                if field.nested_types:
                    query += f"\n\t{field.name} {field.type}<{nested}>,"
                else:
                    query += f"\n\t{field.name} {field.type},"
        query = query[:-1]
        query += "\n);"

        if formatted is False:
            query = query.replace("\n\t", " ").replace("( ", "(").replace("\n);", ");")
        return [query]


@dataclass
class FunctionMeta:
    """Function metadata."""

    keyspace: str
    name: str
    function_name: str
    keyspace_name: str
    argument_names: List[str]
    argument_types: List[str]
    called_on_null_input: bool
    language: str
    body: str
    return_type: str

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate function.
        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        function name in CREATE statement.
        For example CREATE FUNCTION keyspace_name.function_name... if with_keyspace
        is set to False, statement will be CREATE FUNCTION function_name..."""

        keyspace = f"{self.keyspace}."
        if with_keyspace is False:
            keyspace = ""
        args = ", ".join([" ".join(k) for k in zip(self.argument_names, self.argument_types)])
        query = f"CREATE FUNCTION {keyspace}{self.name}({args})\n\t"
        if self.called_on_null_input:
            query += "CALLED ON NULL INPUT\n\t"
        else:
            query += "RETURNS NULL ON NULL INPUT\n\t"
        query += f"RETURNS {self.return_type}\n\t"
        query += f"LANGUAGE {self.language}\n\tAS $${self.body}$$;"

        if formatted is False:
            query = query.replace("\n\t", " ")
        return [query]


@dataclass
class AggregateMeta:
    """Aggregate metadata."""

    keyspace: str
    keyspace_name: str
    name: str
    aggregate_name: str
    argument_types: List[str]
    initcond: str
    state_func: str
    state_type: str
    final_func: str
    return_type: str

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate aggregate.
        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        function name in CREATE statement.
        For example CREATE AGGREGATE keyspace_name.aggregate_name... if with_keyspace
        is set to False, statement will be CREATE AGGREGATE aggregate_name..."""

        keyspace = f"{self.keyspace}."
        if with_keyspace is False:
            keyspace = ""
        args = ", ".join(self.argument_types)
        query = f"CREATE AGGREGATE {keyspace}{self.name}({args})\n\t"
        query += f"SFUNC {self.state_func}\n\t"
        query += f"STYPE {self.state_type}\n\t"
        query += f"FINALFUNC {self.final_func}\n\t"
        query += f"INITCOND {self.initcond};"

        if formatted is False:
            query = query.replace("\n\t", " ")
        return [query]


@dataclass
class ColumnMeta:
    """Column metadata."""

    name: str
    type: str
    clustering_order: str
    column_name: str
    column_name_bytes: bytes
    keyspace_name: str
    kind: str
    position: int
    table_name: str


@dataclass
class IndexMeta:
    """Index metadata."""

    keyspace: str
    table: str
    name: str
    kind: str
    target: str
    options: Dict[str, str]

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate this index.

        If with_keyspace is set to True, keyspace name will be added before
        index name in CREATE statement.
        For example CREATE INDEX keyspace_name.index_name...
        if with_keyspace is set to False, statement will be
        CREATE INDEX index_name...
        """

        keyspace = f"{self.keyspace}."
        if with_keyspace is False:
            keyspace = ""
        target = self.target
        if target.startswith('{"pk":["'):
            target = json.loads(target)
            pk = ",".join([k for k in target["pk"]])
            ck = ",".join([k for k in target["ck"]])
            target = f"(({pk}), {ck})"
        query = f"CREATE INDEX {self.name} ON {keyspace}{self.table} ({target});"

        if formatted is False:
            query = query.replace("\n\t", " ")
        return [query]


@dataclass
class MaterializedViewMeta:
    """Materialized view metadata."""

    keyspace: str
    name: str
    id: UUID
    base_table_id: UUID
    base_table_name: str
    bloom_filter_fp_chance: float
    caching: Dict[str, str]
    comment: str
    compaction: Dict[str, str]
    compression: Dict[str, str]
    crc_check_chance: float
    dclocal_read_repair_chance: float
    default_time_to_live: int
    extensions: Dict[str, str]
    gc_grace_seconds: int
    include_all_columns: bool
    keyspace_name: str
    max_index_interval: int
    memtable_flush_period_in_ms: int
    min_index_interval: 128
    read_repair_chance: int
    speculative_retry: str
    view_name: str
    where_clause: str
    columns: []

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate this
        materialized view.

        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        materialized view name in CREATE statement.
        For example CREATE MATERIALIZED VIEW keyspace_name.view_name...
        if with_keyspace is set to False, statement will be
        CREATE MATERIALIZED VIEW view_name..."""

        keyspace = f"{self.keyspace_name}."
        if with_keyspace is False:
            keyspace = ""
        query = f"CREATE MATERIALIZED VIEW {keyspace}{self.name} AS\n\t"
        if self.include_all_columns is True:
            query += "SELECT *\n\t"
        else:
            columns = ", ".join([k.column_name for k in self.columns])
            query += f"SELECT {columns}\n\t"
        query += f"FROM {keyspace}{self.base_table_name}\n\t"
        query += f"WHERE {self.where_clause}\n\t"
        pk = ", ".join([k.column_name for k in self.columns if k.kind in ("partition_key", "clustering")])
        query += f"PRIMARY KEY ({pk})\n\t"
        order = ", ".join(
            [
                f"{k.column_name} {k.clustering_order.upper()}"
                for k in self.columns
                if k.clustering_order.upper() != "NONE"
            ]
        )
        query += f"WITH CLUSTERING ORDER BY ({order})\n\t"
        query += f"AND bloom_filter_fp_chance = {self.bloom_filter_fp_chance}\n\t"
        query += f"AND caching = {self.caching}\n\t"
        query += f"AND comment = '{self.comment}'\n\t"
        query += f"AND compaction = {self.compaction}\n\t"
        query += f"AND compression = {self.compression}\n\t"
        query += f"AND crc_check_chance = {self.crc_check_chance}\n\t"
        query += f"AND gc_grace_seconds = {self.gc_grace_seconds}\n\t"
        query += f"AND max_index_interval = {self.max_index_interval}\n\t"
        query += f"AND memtable_flush_period_in_ms = {self.memtable_flush_period_in_ms}\n\t"
        query += f"AND min_index_interval = {self.min_index_interval}\n\t"
        query += f"AND speculative_retry = '{self.speculative_retry}';"

        if formatted is False:
            query = query.replace("\n\t", " ")
        return [query]


@dataclass
class TableMeta:
    """Table metadata."""

    id: UUID = None
    name: str = None
    table_name: str = None
    keyspace_name: str = None
    is_virtual: bool = None
    bloom_filter_fp_chance: float = None
    caching: Dict[str, str] = None
    comment: str = None
    compaction: Dict[str, str] = None
    compression: Dict[str, str] = None
    crc_check_chance: float = None
    dclocal_read_repair_chance: float = None
    default_time_to_live: int = None
    extensions: Dict[str, str] = None
    flags: Set[str] = None
    gc_grace_seconds: int = None
    max_index_interval: int = None
    memtable_flush_period_in_ms: int = None
    min_index_interval: int = None
    read_repair_chance: float = None
    speculative_retry: str = None
    columns: List[ColumnMeta] = None
    indexes: List[IndexMeta] = None
    materialized_views: List[MaterializedViewMeta] = None

    def as_cql_query(self, formatted=False, with_keyspace=True, full_schema=True) -> List[str]:
        """If full_schema is set to True returns a CQL query that can be used
        to recreate this table include indexes and materialized views creations.

        If formatted is set to True, extra whitespace will be added to make
        the query human readable.

        If with_keyspace is set to True, keyspace name will be added before
        table name in CREATE statement.
        For example CREATE TABLE keyspace_name.table_name... if with_keyspace
        is set to False, statement will be CREATE TABLE table_name..."""

        keyspace = f"{self.keyspace_name}."
        if with_keyspace is False:
            keyspace = ""
        query = f"CREATE TABLE {keyspace}{self.table_name} (\n\t"
        for colum in self.columns:
            query += f"{colum.name} {colum.type},\n\t"
        pk = ", ".join([k.column_name for k in self.columns if k.kind in ("partition_key", "clustering")])
        query += f"PRIMARY KEY ({pk})\n"
        order = ", ".join(
            [
                f"{k.column_name} {k.clustering_order.upper()}"
                for k in self.columns
                if k.clustering_order.upper() != "NONE"
            ]
        )
        if order:
            query += f") WITH CLUSTERING ORDER BY ({order})\n\t"
            query += f"AND bloom_filter_fp_chance = {self.bloom_filter_fp_chance}\n\t"
        else:
            query += f") WITH bloom_filter_fp_chance = {self.bloom_filter_fp_chance}\n\t"
        query += f"AND caching = {self.caching}\n\t"
        query += f"AND comment = '{self.comment}'\n\t"
        query += f"AND compaction = {self.compaction}\n\t"
        query += f"AND compression = {self.compression}\n\t"
        query += f"AND crc_check_chance = {self.crc_check_chance}\n\t"
        query += f"AND default_time_to_live = {self.default_time_to_live}\n\t"
        query += f"AND gc_grace_seconds = {self.gc_grace_seconds}\n\t"
        query += f"AND max_index_interval = {self.max_index_interval}\n\t"
        query += f"AND memtable_flush_period_in_ms = {self.memtable_flush_period_in_ms}\n\t"
        query += f"AND min_index_interval = {self.min_index_interval}\n\t"
        query += f"AND speculative_retry = '{self.speculative_retry}';"

        if formatted is False:
            query = query.replace("\n\t", " ").replace("( ", "(").replace("\n)", ")")
        query = [query]
        if full_schema is True:
            for index in self.indexes:
                query += index.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)
            for materialized_view in self.materialized_views:
                query += materialized_view.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)

        return query


@dataclass
class KeyspaceMeta:
    """Keyspace metadata."""

    name: str = None
    is_virtual: bool = None
    durable_writes: bool = None
    keyspace_name: str = None
    replication: Dict[str, str] = None
    user_types: List[UserTypeMeta] = None
    functions: List[FunctionMeta] = None
    aggregates: List[AggregateMeta] = None
    tables: List[TableMeta] = None

    def as_cql_query(self, formatted=False, with_keyspace=True, full_schema=True) -> List[str]:
        """If full_schema is set to True returns a CQL query string that can
        be used to recreate the entire keyspace including UDT, functions,
        tables, indexes and materialized views.

        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        UDT name, function name, table name and materialized view name in
        CREATE statement.
        For example CREATE TABLE keyspace_name.table_name... if with_keyspace
        is set to False, statement will be CREATE TABLE table_name..."""

        query = [
            f"CREATE KEYSPACE {self.name} "
            f"WITH replication = {self.replication} "
            f"AND durable_writes = {self.durable_writes};"
        ]
        if full_schema is True:
            for user_type in self.user_types:
                query += user_type.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)
            for function in self.functions:
                query += function.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)
            for aggregate in self.aggregates:
                query += aggregate.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)
            for table in self.tables:
                query += table.as_cql_query(formatted=formatted, with_keyspace=with_keyspace, full_schema=full_schema)
        return query
