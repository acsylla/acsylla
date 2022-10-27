[![CI](https://github.com/acsylla/acsylla/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/acsylla/acsylla/actions/workflows/ci.yml)
[![CI](https://github.com/acsylla/acsylla/actions/workflows/release.yml/badge.svg?branch=v0.1.7a0)](https://github.com/acsylla/acsylla/actions/workflows/release.yml)
[![PyPI](https://img.shields.io/pypi/v/acsylla.svg)](https://pypi.org/project/acsylla/)
[![Number of PyPI downloads](https://img.shields.io/pypi/dm/acsylla.svg)](https://pypi.org/project/acsylla/)
[![Documentation Status](https://readthedocs.org/projects/acsylla/badge/?version=latest)](https://acsylla.readthedocs.io/en/latest/)

# Acsylla <img align="right" width="200px" src="https://raw.githubusercontent.com/acsylla/acsylla/master/logo/cassandra-scylladb.svg" />
A composition of ***async*** + ***cassandra*** + ***scylla*** words.


## A high performance Python Asyncio client library for Cassandra and ScyllaDB 
Under the hood **_acsylla_** has modern, feature-rich and shard-aware [C/C++ client](https://github.com/scylladb/cpp-driver) library for [Cassandra](https://cassandra.apache.org) and [ScyllaDB](https://www.scylladb.com).

## Table of Contents
  * [Features](#features)
  * [Compatibility](#compatibility)
  * [Install](#install)
    * [Build your own package](#build-your-own-package) 
  * [Cluster](#cluster) 
    * [Configuration options](#configuration-options)
    * [Configuration methods](#configuration-methods)
  * [Session](#session)
    * [Methods of Session object](#methods-of-session-object)
  * [Statement](#statement)
    * [Methods of Statement object](#methods-of-statement-object)
  * [PreparedStatement](#preparedstatement)
    * [Methods of PreparedStatement object](#methods-of-preparedstatement-object)
  * [Batch](#batch)
    * [Methods of Batch object](#methods-of-batch-object)
  * [Result](#result)
    * [Methods of Result object](#methods-of-result-object)
  * [Row](#row)
    * [Methods of Row object](#methods-of-row-object)
  * [Examples](#examples)
    * [Basic usage](#basic-usage)
    * [Binding Parameters](#binding-parameters)
      * [Non Prepared Statement](#non-prepared-statement)
      * [Prepared Statement](#prepared-statement)
    * [Use prepared statement and paging](#use-prepared-statement-and-paging)
    * [Configure Shard-Awareness connection](#configure-shard-awareness-connection-to-scylladb-cluster)
    * [SSL Example](#ssl-example)
    * [Retrieving metadata](#retrieving-metadata)
    * [Configure logging](#configure-logging)
      * [Set log level](#set-log-level)
      * [Set callback for capture log messages](#set-callback-for-capture-log-messages)
    * [Execution profiles](#execution-profiles)
    * [Tracing](#tracing)
  * [Developing](#developing)
  

## Features

* Shard-Awareness
* Asynchronous API
* Simple, Prepared, and Batch statements
* Asynchronous I/O, parallel execution, and request pipelining
* Connection pooling
* Automatic node discovery
* Automatic reconnection
* Configurable load balancing
* Works with any cluster size
* Authentication
* SSL
* Latency-aware routing
* Performance metrics
* Tuples and UDTs
* Nested collections
* Retry policies
* Client-side timestamps
* Data types
* Idle connection heartbeats
* Support for materialized view and secondary index metadata
* Support for clustering key order, `frozen<>` and Cassandra version metadata
* Whitelist/blacklist DC, and whitelist/blacklist hosts load balancing policies
* Custom authenticators
* Reverse DNS with SSL peer identity verification support
* Randomized contact points
* Speculative execution

## Compatibility

This driver works exclusively with the Cassandra Query Language v3 (CQL3) and
Cassandra's native protocol. The current version works with:

* Scylla and Scylla Enterprise
* Apache Cassandra® versions 2.1, 2.2 and 3.0+
* Python 3.7, 3.8, 3.9, 3.10 and 3.11 for Linux and MacOS 

## Install

There is an Beta realease compabitble with Python 3.7, 3.8, 3.9, 3.10 and 3.11 for Linux and MacOS environments uploaded as a Pypi package. Use the following
command for installing it:

```bash
pip install acsylla
```

### Build your own package
You can build your own package for any supported python version for ***x86_64*** and ***aarch64*** Linux.

Example for build wheel for Python 3.11 aarch64 from master branch
```bash
curl -O https://raw.githubusercontent.com/acsylla/acsylla/master/bin/build.sh
curl -O https://raw.githubusercontent.com/acsylla/acsylla/master/bin/build_in_docker.sh
chmod +x build.sh build_in_docker.sh
./build_in_docker.sh 3.11 master aarch64
```

## Cluster

The `Cluster` object describes a Cassandra/ScyllaDB cluster’s configuration. 
The ***default cluster object is good for most clusters*** and only requires a single 
or multiple list of contact points in order to establish a session connection.   
***For example:***   
`cluster = acsylla.create_cluster('127.0.0.1, 127.0.0.2')`

Once a session is connected using a cluster object its configuration is constant. 

Modifying the cluster object configuration once a session is established does not alter the session’s configuration.

### Configuration options

List of named arguments to configure cluster with  `acsylla.create_cluster` helper. 

- ***contact_points:*** Sets contact points. This MUST be set. White space is striped from the contact points.    
    *Examples:* “127.0.0.1”,  “127.0.0.1,127.0.0.2”, “server1.domain.com”

- ***port:*** Sets the port.  
    *Default:* 9042

- ***local_address:*** Sets the local address to bind when connecting to the
    cluster, if desired. IP address to bind, or empty string for no
    binding. Only numeric addresses are supported; no resolution is done.

- ***local_port_range_min:*** Sets the range of outgoing port numbers (ephemeral
    ports) to be used when establishing the shard-aware connections. This
    is applicable when the routing of connection to shard is based on the
    client-side port number.  
    When application connects to multiple CassCluster-s it is advised
    to assign mutually non-overlapping port intervals to each. It is assumed
    that the supplied range is allowed by the OS (e.g. it fits inside
    /proc/sys/net/ipv4/ip_local_port_range on *nix systems)  
    *Default:* `49152`

- ***local_port_range_max:*** See `local_port_range_min`  
    *Default:* `65535`

- ***username:*** Set username for plain text authentication.

- ***password:*** Set password for plain text authentication.

- ***connect_timeout:*** Sets the timeout for connecting to a node.  
    *Default:* `5` seconds

- ***request_timeout:*** Sets the timeout for waiting for a response from a node.
    Use 0 for no timeout.  
    *Default:* `12` seconds

- ***resolve_timeout:*** Sets the timeout for waiting for DNS name resolution.  
    *Default:* `2` seconds

- ***log_level:*** Sets the log level.
    Available levels: 
  - `disabled`
  - `critical`
  - `error`
  - `warn`
  - `info`
  - `debug`
  - `trace`
  
  *Default:* `warn`

- ***logging_callback:*** Sets a callback function to catch log messages.  
    *Default:* An internal logger with "acsylla" name.
    `logging.getLogger('acsylla')`

- ***ssl_enable:*** Enable SSL connection  
    *Default:* `False`

- ***ssl_cert:*** Set client-side certificate chain. This is used to authenticate
    the client on the server-side. This should contain the entire
    Certificate chain starting with the certificate itself

- ***ssl_private_key:*** Set client-side private key. This is used to authenticate
    the client on the server-side.

- ***ssl_private_key_password:*** Password for `ssl_private_key`

- ***ssl_trusted_cert:*** Adds a trusted certificate. This is used to verify the
    peer’s certificate.

- ***ssl_verify_flags:*** Sets verification performed on the peer’s certificate.
    - `NONE` No verification is performed
    - `PEER_CERT` Certificate is present and valid
    - `PEER_IDENTITY` IP address matches the certificate’s common name or one
          of its subject alternative names. This implies the certificate is
          also present.
    - `PEER_IDENTITY_DNS` Hostname matches the certificate’s common name or
          one of its subject alternative names. This implies the certificate
          is also present.  
      *Default:* `PEER_CERT`

- ***protocol_version:*** Sets the protocol version. The driver will automatically
    downgrade to the lowest supported protocol version.  
    *Default:* `acsylla.ProtocolVersion.V4` or `acsylla.ProtocolVersion.DSEV1` when
    using the DSE driver with DataStax Enterprise.

- ***use_beta_protocol_version:*** Use the newest beta protocol version. This
    currently enables the use of protocol version `cyacsylla.ProtocolVersion.V5`
    or `cyacsylla.ProtocolVersion.DSEV2` when using the DSE driver with
    DataStax Enterprise.  
    *Default:* `False`

- ***consistency:*** Sets default consistency level of statement. `acsylla.Consistency`  
    *Default:* `LOCAL_ONE`

- ***serial_consistency:*** Sets default serial consistency level of statement. `acsylla.Consistency`   
    *Default:* `ANY`

- ***queue_size_io:*** Sets the size of the fixed size queue that stores pending
    requests.  
    *Default:* `8192`

- ***core_connections_per_host:*** Sets the number of connections made to each
    server in each IO thread.  
    *Default:* `1`

- ***constant_reconnect_delay_ms:*** Configures the cluster to use a reconnection
    policy that waits a constant time between each reconnection attempt.
    Time in milliseconds to delay attempting a reconnection; 0 to perform
    a reconnection immediately.  
    *Default:* Not set

- ***exponential_reconnect_base_delay_ms:*** The base delay (in milliseconds) to
    use for scheduling reconnection attempts.
    Configures the cluster to use a reconnection policy that waits
    exponentially longer between each reconnection attempt; however will
    maintain a constant delay once the maximum delay is reached.    
    *Note:* A random amount of jitter (+/- 15%) will be added to the pure
    exponential delay value. This helps to prevent situations where
    multiple connections are in the reconnection process at exactly the
    same time. The jitter will never cause the delay to be less than the
    base delay, or more than the max delay.  
    *Default:* `2000`

- ***exponential_reconnect_max_delay_ms:*** The maximum delay to wait between two
    reconnection attempts. See `exponential_reconnect_max_delay_ms`  
    *Default:* `60000`

- ***coalesce_delay_us:*** Sets the amount of time, in microseconds, to wait for
    new requests to coalesce into a single system call. This should be set
    to a value around the latency SLA of your application’s requests while
    also considering the request’s roundtrip time. Larger values should be
    used for throughput bound workloads and lower values should be used for
    latency bound workloads.  
    *Default:* `200` us

- ***new_request_ratio:*** Sets the ratio of time spent processing new requests
    versus handling the I/O and processing of outstanding requests. The
    range of this setting is 1 to 100, where larger values allocate more
    time to processing new requests and smaller values allocate more time
    to processing outstanding requests.  
    *Default:* `50`

- ***max_schema_wait_time_ms:*** Sets the maximum time to wait for schema
    agreement after a schema change is made (e.g. creating, altering,
    dropping a table/keyspace/view/index etc).  
    *Default:* `10000` milliseconds

- ***tracing_max_wait_time_ms:*** Sets the maximum time to wait for tracing data to become available.  
    *Default:* `15` milliseconds

- ***tracing_retry_wait_time_ms:*** Sets the amount of time to wait between attempts to check to see if tracing is available.  
    *Default:*  `3` milliseconds

- ***tracing_consistency:*** Sets the consistency level to use for checking to see if tracing data is available.  
    *Default:* `ONE`

- ***load_balance_round_robin:*** Configures the cluster to use round-robin load
    balancing. The driver discovers all nodes in a cluster and cycles
    through them per request. All are considered local.

- ***load_balance_dc_aware:*** The primary data center to try first.
    Configures the cluster to use DC-aware load balancing. For each query,
    all live nodes in a primary ‘local’ DC are tried first, followed by any
    node from other DCs.  
    *Note:* This is the default, and does not need to be called unless
    switching an existing from another policy or changing settings. Without
    further configuration, a default local_dc is chosen from the first
    connected contact point, and no remote hosts are considered in query
    plans. If relying on this mechanism, be sure to use only contact points
    from the local DC.

- ***token_aware_routing:*** Configures the cluster to use token-aware request
    routing or not. This routing policy composes the base routing policy,
    routing requests first to replicas on nodes considered ‘local’ by the
    base load balancing policy.  
    *Important:* Token-aware routing depends on keyspace metadata. For this
    reason enabling token-aware routing will also enable retrieving and
    updating keyspace schema metadata.  
    *Default:* `True` (enabled).

- ***token_aware_routing_shuffle_replicas:*** Configures token-aware routing to
    randomly shuffle replicas. This can reduce the effectiveness of
    server-side caching, but it can better distribute load over replicas
    for a given partition key.  
    *Note:* Token-aware routing `token_aware_routing` must be enabled for the
    setting to be  applicable.    
    *Default:* `True` (enabled).

- ***latency_aware_routing:*** Configures the cluster to use latency-aware request
    routing or not. This routing policy is a top-level routing policy. It
    uses the base routing policy to determine locality (dc-aware) and/or
    placement (token-aware) before considering the latency.  
    *Default:* `False` (disabled).

- ***latency_aware_routing_settings:*** Configures the settings for latency-aware
    request routing. Instance of `acsylla.LatencyAwareRoutingSettings`  
    *Default:* 
    - `exclusion_threshold` ***2.0*** *Controls how much worse the latency
                                      be compared to the average latency of
                                      the best performing node before it
                                      penalized.*
    - `scale_ms` ***100 milliseconds*** *Controls the weight given to older
                                      latencies when calculating the average
                                      latency of a node. A bigger scale will
                                      give more weight to older latency
                                      measurements.*
    - `retry_period_ms` ***10,000 milliseconds*** *The amount of time a node is
                                      penalized by the policy before being
                                      given a second chance when the current
                                      average latency exceeds the calculated
                                      threshold (exclusion_threshold *
                                      best_average_latency).*
    - `update_rate_ms` ***100 milliseconds*** *The rate at which the best
                                      average latency is recomputed.*
    - `min_measured` ***50*** *The minimum number of measurements per-host
                                      required to be considered by the policy*

- ***whitelist_hosts:*** Sets whitelist hosts. The first call sets the whitelist
    hosts and any subsequent calls appends additional hosts. Passing an
    empty string will clear and disable the whitelist. White space is
    striped from the hosts.  
    This policy filters requests to all other policies, only allowing
    requests to the hosts contained in the whitelist. Any host not in the
    whitelist will be ignored and a connection will not be established.
    This policy is useful for ensuring that the driver will only connect to
    a predefined set of hosts.  
    *Examples*: “127.0.0.1”, “127.0.0.1,127.0.0.2”

- ***blacklist_hosts:*** Sets blacklist hosts. The first call sets the blacklist
    hosts and any subsequent calls appends additional hosts. Passing an
    empty string will clear and disable the blacklist. White space is
    striped from the hosts.  
    This policy filters requests to all other policies, only allowing
    requests to the hosts not contained in the blacklist. Any host in the
    blacklist will be ignored and a connection will not be established.
    This policy is useful for ensuring that the driver will not connect to
    a predefined set of hosts.  
    *Examples*: “127.0.0.1”, “127.0.0.1,127.0.0.2”

- ***whitelist_dc:*** Same as `whitelist_hosts`, but whitelist all hosts of a dc  
    *Examples*: “dc1”, “dc1,dc2”

- ***blacklist_dc:*** Same as `blacklist_hosts`, but blacklist all hosts of a dc  
    *Examples*: “dc1”, “dc1,dc2”

- ***tcp_nodelay:*** Enable/Disable Nagle’s algorithm on connections.  
    *Default:* True

- ***tcp_keepalive_sec:*** Set keep-alive delay in seconds.  
    *Default:* disabled

- ***timestamp_gen:*** "server_side" or "monotonic" Sets the timestamp generator
    used to assign timestamps to all requests unless overridden by setting
    the timestamp on a statement or a batch.  
    *Default:* Monotonically increasing, client-side timestamp generator.

- ***heartbeat_interval_sec:*** Sets the amount of time between heartbeat messages
    and controls the amount of time the connection must be idle before
    sending heartbeat messages. This is useful for preventing intermediate
    network devices from dropping connections.  
    *Default:* 30 seconds

- ***idle_timeout_sec:*** Sets the amount of time a connection is allowed to be
    without a successful heartbeat response before being terminated and
    scheduled for reconnection.  
    *Default:* 60 seconds

- ***retry_policy:*** May be set to `default` or `fallthrough` Sets the retry policy used for
    all requests unless overridden by setting a retry policy on a statement
    or a batch.
    - `default` This policy retries queries in the following cases:
      - On a read timeout, if enough replicas replied but data was not received.
      - On a write timeout, if a timeout occurs while writing the distributed batch log 
      - On unavailable, it will move to the next host
      - In all other cases the error will be returned. This policy always uses the query’s original consistency level.
    - `fallthrough` This policy never retries or ignores a server-side
        failure. The error is always returned.  

    *Default:* `default` This policy will retry on a read timeout if there
    was enough replicas, but no data present, on a write timeout if a
    logged batch request failed to write the batch log, and on a
    unavailable error it retries using a new host. In all other cases the
    default policy will return an error.

- ***retry_policy_logging:*** This policy logs the retry decision of its child
    policy. Logging is done using INFO level.  
    *Default:* False

- ***use_schema:*** Enable/Disable retrieving and updating schema metadata. If
    disabled this is allows the driver to skip over retrieving and updating
    schema metadata and `session.get_metadata()` will
    always return an empty object. This can be useful for reducing the
    startup overhead of short-lived sessions.  
    *Default:* True (enabled)

- ***hostname_resolution:*** Enable retrieving hostnames for IP addresses
    using reverse IP lookup. This is useful for authentication (Kerberos)
    or encryption (SSL) services that require a valid hostname for
    verification.  
    *Default:* False (disabled)

- ***randomized_contact_points:*** Enable/Disable the randomization of the contact
    points list.  
    *Important:* This setting should only be disabled for debugging or tests.  
    *Default:* True (enabled)

- ***speculative_execution_policy:*** Enable constant speculative executions with
    the supplied settings `acsylla.SpeculativeExecutionPolicy`.

- ***max_reusable_write_objects:*** Sets the maximum number of “pending write”
    objects that will be saved for re-use for marshalling new requests.
    These objects may hold on to a significant amount of memory and
    reducing the number of these objects may reduce memory usage of the
    application.  
       The cost of reducing the value of this setting is potentially slower
    marshalling of requests prior to sending.  
    *Default:* Max unsigned integer value

- ***prepare_on_all_hosts:*** Prepare statements on all available hosts.  
    *Default:* True

- ***no_compact:*** Enable the NO_COMPACT startup option. This can help facilitate
    uninterrupted cluster upgrades where tables using COMPACT_STORAGE will
    operate in “compatibility mode” for BATCH, DELETE, SELECT, and UPDATE
    CQL operations.  
    *Default:* False

- ***host_listener_callback:*** Sets a callback for handling host state changes in
    the cluster.
    Note: The callback is invoked only when state changes in the cluster
    are applicable to the configured load balancing policy(s).
    NOT IMPLEMENTED YET

- ***application_name:*** Set the application name. This is optional; however it
    provides the server with the application name that can aid in debugging
    issues with larger clusters where there are a lot of client (or
    application) connections.

- ***application_version:*** Set the application version. This is optional;
    however it provides the server with the application version that can
    aid in debugging issues with large clusters where there are a lot of
    client (or application) connections that may have different versions
    in use.

- ***client_id:*** Set the client id. This is optional; however it provides the
    server with the client ID that can aid in debugging issues with large
    clusters where there are a lot of client connections.  
    *Default:* UUID v4 generated

- ***monitor_reporting_interval_sec:*** Sets the amount of time between monitor
    reporting event messages.  
    *Default:* 300 seconds.

- ***cloud_secure_connection_bundle:*** Absolute path to DBaaS credentials file.  
    Sets the secure connection bundle path for processing DBaaS credentials.
    This will pre-configure a cluster using the credentials format provided
    by the DBaaS cloud provider.  
    *Note:* `contact_points` and `ssl_enable` should not used in conjunction
    with `cloud_secure_connection_bundle`.
  
    ***Example:*** "/path/to/secure-connect-database_name.zip"  
    *Default:* None

- ***dse_gssapi_authenticator:*** Enables GSSAPI authentication for DSE clusters
    secured with the DseAuthenticator.
    Instance of `acsylla.DseGssapiAuthenticator`

- ***dse_gssapi_authenticator_proxy:*** Enables GSSAPI authentication with proxy
    authorization for DSE clusters secured with the DseAuthenticator.
    Instance of `acsylla.DseGssapiAuthenticatorProxy`

- ***dse_plaintext_authenticator:*** Enables plaintext authentication for DSE
    clusters secured with the DseAuthenticator.
    Instance of `acsylla.DsePlaintextAuthenticator`

- ***dse_plaintext_authenticator_proxy:*** Enables plaintext authentication with
    proxy authorization for DSE clusters secured with the DseAuthenticator.
    Instance of `acsylla.DsePlaintextAuthenticatorProxy`

### Configuration methods

For full list of methods to configure `Cluster` see [base.py](./acsylla/base.py)

## Session

A session object is used to execute queries and maintains cluster state through 
the control connection. The control connection is used to auto-discover nodes 
and monitor cluster changes (topology and schema). Each session also maintains 
multiple pools of connections to cluster nodes which are used to query the cluster.

```python
import acsylla
    
cluster = acsylla.create_cluster(['localhost'])
session = await cluster.create_session(keyspace="acsylla")
```

### Methods of `Session` object

- ***async def close(self):***  
 Closes the session instance, outputs a close future which can be used to 
    determine when the session has been terminated. This allows in-flight 
    requests to finish.

- ***async def set_keyspace(self, keyspace: str) -> "Result":***  
 Sets the keyspace for session

- ***def get_client_id(self) -> str:***  
 Get the client id.

- ***def get_metadata(self):***  
 Returns `Metadata` instance class for retrieving metadata from cluster.

- ***async def create_prepared(self, statement: str, timeout: Optional[float] = None) -> PreparedStatement:***  
 Create a prepared statement.  
 By providing a `timeout` all requests built by the prepared statement will use it, otherwise timeout provided during the `Cluster` instantantation will be used. Value expected is seconds.

- ***async def execute(self, statement: "Statement") -> Result***  
 Executes an statement and returns the `Result` instance.

- ***async def execute_batch(self, batch: Batch) -> Result:***  
 Executes a batch of statements.

- ***def metrics(self) -> SessionMetrics:***  
 Returns the metrics related to the session.

- ***def speculative_execution_metrics(self) -> SpeculativeExecutionMetrics:***  
 Returns speculative execution performance metrics gathered by the driver.

## Statement

A statement object is an executable query. It represents either a regular 
(adhoc) statement or a prepared statement. It maintains the queries’ parameter 
values along with query options (consistency level, paging state, etc.)

### Methods of `Statement` object

- ***def add_key_index(self, index: int) -> None:***  
 Adds a key index specifier to this a statement. When using
    token-aware routing, this can be used to tell the driver which
    parameters within a non-prepared, parameterized statement are part of
    the partition key.  
 Use consecutive calls for composite partition keys.  
 This is not necessary for prepared statements, as the key parameters
    are determined in the metadata processed in the prepare phase.

- ***def reset_parameters(self, count: int) -> None:***  
 Clear and/or resize the statement’s parameters.

- ***def bind(self, index: int, value: SupportedType) -> None:***   
Binds the value to a specific index parameter.   
If an invalid type is used for a prepared statement this will raise
    immediately an error. If a none prepared exception is used error will
    be raised later during the execution statement.   
If an invalid index is used this will raise immediately an error

- ***def bind_by_name(self, name: str, value: SupportedType) -> None:***   
Binds the the value to a specific parameter by name.   
If an invalid type is used for this will raise immediately an error. If an
    invalid name is used this will raise immediately an error

- ***def bind_list(self, values: Sequence[SupportedType]) -> None:***    
Binds the values into all parameters from left to right.    
For types supported and errors that this function might raise take
    a look at the `Statement.bind` function.

- ***def bind_dict(self, values: Mapping[str, SupportedType]) -> None:***    
Binds the values into all parameter names. Names are the keys
    of the mapping provided.
For types supported and errors that this function might raise take    
    look at the `Statement.bind_dict` function.
Note: This method are only allowed for statements created using
    prepared statements

- ***def set_page_size(self, page_size: int) -> None:***  
 Sets the statement's page size.

- ***def set_page_state(self, page_state: bytes) -> None:***  
 Sets the statement's paging state. This can be used to get the next
    page of data in a multi-page query.  
 *Warning:* The paging state should not be exposed to or come from
    untrusted environments. The paging state could be spoofed and potentially
    used to gain access to other data.


- ***def set_timeout(self, timeout: float) -> None:***  
 Sets the statement's timeout in seconds for waiting for a response from a node.  
 *Default:* Disabled (use the cluster-level request timeout)


- ***def set_consistency(self, timeout: float) -> None:***  
 Sets the statement’s consistency level.  
 *Default:* LOCAL_ONE

- ***def set_serial_consistency(self, timeout: float) -> None:***  
 Sets the statement’s serial consistency level.  
 *Default:* Not set

- ***def set_timestamp(self, timestamp: int):***  
 Sets the statement’s timestamp.

- ***def set_is_idempotent(self, is_idempotent: bool):***  
 Sets whether the statement is idempotent. Idempotent statements are
    able to be automatically retried after timeouts/errors and can be
    speculatively executed.

- ***def set_retry_policy(self, retry_policy: str, retry_policy_logging: bool = False):***  
 Sets the statement’s retry policy.  
 May be set to `default` or `fallthrough`
    - `default` This policy retries queries in the following cases:
      - On a read timeout, if enough replicas replied but data was not received.
      - On a write timeout, if a timeout occurs while writing the distributed batch log 
      - On unavailable, it will move to the next host
      - In all other cases the error will be returned. This policy always uses the query’s original consistency level.
    - `fallthrough` This policy never retries or ignores a server-side
        failure. The error is always returned.   
    *Default:* `default` This policy will retry on a read timeout if there
    was enough replicas, but no data present, on a write timeout if a
    logged batch request failed to write the batch log, and on a
    unavailable error it retries using a new host. In all other cases the
    default policy will return an error.
    - `retry_policy_logging` If set to `True`, this policy logs the retry decision of its child
        policy. Logging is done using `INFO` level. *Default:* `False`

- ***def set_tracing(self, enabled: bool = None):***  
 Sets whether the statement should use tracing.

- ***def set_host(self, host: str, port: int = 9042):***  
 Sets a specific host that should run the query.  
 In general, this should not be used, but it can be useful in the
    following situations:  
 To query node-local tables such as system and virtual tables.  
 To apply a sequence of schema changes where it makes sense for all 
    the changes to be applied on a single node.

- ***def set_execution_profile(self, name: str) -> None:***  
 Sets the execution profile to execute the statement with.
    Note: Empty string will clear execution profile from statement

## PreparedStatement

A statement that has been prepared cluster-side (It has been pre-parsed and cached).
 

### Methods of `PreparedStatement` object
Use the `session.create_prepared()` coroutine for creating a new instance of `PreparedStatement`.
```python
prepared = await session.create_prepared("SELECT id, value FROM test")
statement = prepared.bind(page_size=10)
```
- ***def bind(self, page_size: Optional[int] = None, page_state: Optional[bytes] = None, execution_profile: Optional[str] = None,) -> Statement:***  
 Returns a new `Statement` using the prepared.

- ***def set_execution_profile(self, statement: Statement, name: str) -> None:***  
 Sets the execution profile to execute the statement with.  
 ***Note:*** Empty string will clear execution profile from statement

## Batch
A group of statements that are executed as a single batch.

### Methods of `Batch` object
Use the `acsylla.create_batch_logged()`, `acsylla.create_batch_unlogged()` and 
`acsylla.create_batch_counter()` factories for creating a new instance.

- ***def set_consistency(self, consistency: int):***  
 Sets the batch’s consistency level

- ***def set_serial_consistency(self, consistency: int):***  
 Sets the batch’s serial consistency level.

- ***def set_timestamp(self, timestamp: int):***  
 Sets the batch’s timestamp.

- ***def set_request_timeout(self, timeout_ms: int):***  
 Sets the batch’s timeout for waiting for a response from a node.  
 ***Default:*** Disabled (use the cluster-level request timeout)

- ***def set_is_idempotent(self, is_idempotent):***  
 Sets whether the statements in a batch are idempotent. Idempotent
    batches are able to be automatically retried after timeouts/errors and
    can be speculatively executed.

- ***def set_retry_policy(self, retry_policy: str, retry_policy_logging: bool = False):***  
 Sets the batch’s retry policy.  
 May be set to `default` or `fallthrough`
    - `default` This policy retries queries in the following cases:
      - On a read timeout, if enough replicas replied but data was not received.
      - On a write timeout, if a timeout occurs while writing the distributed batch log 
      - On unavailable, it will move to the next host
      - In all other cases the error will be returned. This policy always uses the query’s original consistency level.
    - `fallthrough` This policy never retries or ignores a server-side
        failure. The error is always returned.   
    *Default:* `default` This policy will retry on a read timeout if there
    was enough replicas, but no data present, on a write timeout if a
    logged batch request failed to write the batch log, and on a
    unavailable error it retries using a new host. In all other cases the
    default policy will return an error.
    - `retry_policy_logging` If set to `True`, this policy logs the retry decision of its child
        policy. Logging is done using `INFO` level. *Default:* `False`

- ***def set_tracing(self, enabled: bool):***  
 Sets whether the batch should use tracing.

- ***def add_statement(self, statement: Statement) -> None:***  
 Adds a new statement to the batch.

- ***def set_execution_profile(self, name: str) -> None:***  
 Sets the execution profile to execute the statement with.  
 *Note:* Empty string will clear execution profile from statement

## Result
The result of a query.

### Methods of `Result` object
Provides a result instance class. Use the `session.execute()` coroutine for 
getting the result  from a query

- ***def count(self) -> int:***  
 Returns the total rows of the result

- ***def column_count(self) -> int:***  
 Returns the total columns returned

- ***def columns_names(self):***  
 Returns the columns names

- ***def first(self) -> Optional["Row"]:***  
 Return the first result, if there is no row returns None.

- ***def all(self) -> Iterable["Row"]:***  
 Return the all rows using of a result, using an iterator.   
 If there is no rows iterator returns no rows.

- ***def has_more_pages(self) -> bool:***  
 Returns true if there is still pages to be fetched

- ***def page_state(self) -> bytes:***  
 Returns a token with the page state for continuing fetching
    new results.  
 Before calling this method you must first checks if there are more
    results using the `has_more_pages` function, and if there are use the
    token returned by this function as an argument of the factories for creating
    an statement for returning the next page.

## Row
A collection of column values.
### Methods of `Row` object
Provides access to a row of a `Result`.
```python
result = await session.execute(statement)
for row in result:
    print(row.as_dict())
```

- ***def as_dict(self) -> dict:***  
 Returns the row as dict.

- ***def as_list(self) -> list:***  
 Returns the row as list.

- ***def as_tuple(self) -> tuple:***  
 Returns the row as tuple.

- ***def as_named_tuple(self) -> tuple:***  
 Returns the row as named tuple.

- ***def column_count(self) -> int:***  
 Returns column count.

- ***def column_value(self, name: str) -> SupportedType:***  
 Returns the row column value called by `name`.  
 Raises a `CassException` derived exception if the column can not be found  
 Type is inferred by using the Cassandra driver
    and converted, if supported, to a Python type or one
    of the extended types provided by Acsylla.

- ***def column_value_by_index(self, index):***  
 Returns the column value by `column index`.
    Raises an exception if the column can not be found

## Examples

The driver includes several examples in the [examples](./examples/) directory.

### Basic usage

The following snippet shows the minimal stuff that would be needed for creating a new ``Session``
object for the keyspace ``acsylla`` and then peform a query for reading a set of rows. 
For more info see [base.py](./acsylla/base.py) and [factories.py](./acsylla/factories.py)
Acsylla supports all native datatypes including `Collections` and `UDT`

```python
import asyncio
import acsylla
    
async def main():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    statement = acsylla.create_statement("SELECT id, value FROM test WHERE id=100")
    result = await session.execute(statement)
    row = result.first()
    value = row.column_value("value")
    await session.close()

asyncio.run(main())
```

### Binding Parameters
The ‘?’ marker is used to denote the bind variables in a query string. 
This can be used for both regular and prepared parameterized queries. 

#### Non Prepared Statement
In addition to adding the bind marker to your query string your application 
must also provide the number of bind variables to 
`acsylla.create_statement()` via `parameters` kwargs when constructing a new 
statement.

```python
import asyncio
import acsylla


async def bind_by_index():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    statement = acsylla.create_statement(
        "INSERT INTO test (id, value) VALUES (?, ?)", parameters=2)
    statement.bind(0, 1)
    statement.bind(1, 1)
    await session.execute(statement)


async def bind_list():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    statement = acsylla.create_statement(
        "INSERT INTO test (id, value) VALUES (?, ?)", parameters=2)
    statement.bind_list([1, 1])
    await session.execute(statement)
    
asyncio.run(bind_by_index())
asyncio.run(bind_list())
```

#### Prepared Statement
Bind variables can be bound by the marker’s index or by name and must be 
supplied for all bound variables.

```python
import asyncio
import acsylla


async def bind_by_index():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("INSERT INTO test (id, value) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind(0, 1)
    statement.bind(1, 1)
    await session.execute(statement)


async def bind_by_name():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared(
        "INSERT INTO test (id, value) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind_by_name("id", 1)
    statement.bind_by_name("value", 1)
    await session.execute(statement)


async def bind_list():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared(
        "INSERT INTO test (id, value) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind_list([0, 1])
    await session.execute(statement)


async def bind_dict():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared(
        "INSERT INTO test (id, value) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind_dict({'id': 1, 'value': 1})
    await session.execute(statement)


async def bind_named_parameters():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared(
        "INSERT INTO test (id, value) VALUES (:test_id, :test_value)")
    statement = prepared.bind()
    statement.bind_dict({'test_id': 1, 'test_value': 1})
    await session.execute(statement)


asyncio.run(bind_by_index())
asyncio.run(bind_by_name())
asyncio.run(bind_list())
asyncio.run(bind_dict())
asyncio.run(bind_named_parameters())
```

### Use prepared statement and paging

```python
import asyncio
import acsylla

async def main():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("SELECT id, value FROM test")
    statement = prepared.bind(page_size=10)
    while True:
        result = await session.execute(statement)
        print(result.columns_names())
        # ['id', 'value']
        for row in result:
            print(dict(row))
            # {'id': 1, 'value': 'test'}
            print(list(row))
            # [('id', 1), ('value', 'test')]
            print(row.as_list())
            # [1, 'test']
            print(row.as_tuple())
            # (1, 'test')
        if result.has_more_pages():
            statement.set_page_size(100) # you can change statement settings on the fly
            statement.set_page_state(result.page_state())
        else:
            break

asyncio.run(main())
```

#### Example for pagging result with async generator 

```python
import asyncio
import acsylla

class AsyncResultGenerator:
    def __init__(self, session, statement):
        self.session = session
        self.statement = statement

    async def __aiter__(self):
        result = await self.session.execute(self.statement)
        while True:
            if result.has_more_pages():
                self.statement.set_page_state(result.page_state())
                future_result = asyncio.create_task(
                    self.session.execute(self.statement))
                await asyncio.sleep(0)
            else:
                future_result = None
            for row in result:
                yield dict(row)
            if future_result is not None:
                result = await future_result
            else:
                break
def find(session, statement):
    return AsyncResultGenerator(session, statement)

async def main():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("SELECT id, value FROM test")

    statement = prepared.bind(page_size=10)

    async for res in find(session, statement):
        print(res)

asyncio.run(main())
```

### Configure [Shard-Awareness](https://github.com/scylladb/cpp-driver/tree/master/topics/scylla_specific) connection to ScyllaDB cluster

```python
import acsylla

cluster = acsylla.create_cluster(['node1', 'node2', 'node3'],
    port=19042,                 # default: 9042
    core_connections_per_host=8,# default: 1
    local_port_range_min=49152, # default: 49152
    local_port_range_max=65535  # default: 65535
)
```

### SSL Example

```python
import acsylla

with open('./certs/client.cert.pem') as f:
    ssl_cert = f.read()
with open('./certs/client.key.pem') as f:
    ssl_private_key = f.read()
with open('./certs/trusted.cert.pem') as f:
    ssl_trusted_cert = f.read()

cluster = acsylla.create_cluster(
    ['localhost'],
    ssl_enabled=True,
    ssl_cert=ssl_cert,
    ssl_private_key=ssl_private_key,
    ssl_trusted_cert=ssl_trusted_cert,
    ssl_verify_flags=acsylla.SSLVerifyFlags.PEER_IDENTITY)
```

### Retrieving metadata

```python
import asyncio
import acsylla

async def main():
    cluster = acsylla.create_cluster(['localhost'])
    session = await cluster.create_session(keyspace="acsylla")
    metadata = session.get_metadata()
    for keyspace in metadata.get_keyspaces():
        keyspace_metadata = metadata.get_keyspace_meta(keyspace)
        print('\n\n'.join(keyspace_metadata.as_cql_query(formatted=True)))
    await session.close()

asyncio.run(main())
```

### Configure logging

#### Set log level

Available levels: `disabled` `critical` `error` `warn` `info` `debug` `trace`

```python
import logging
import asyncio
import acsylla

logging.basicConfig(format="[%(levelname)1.1s %(asctime)s] (%(name)s) %(message)s")

async def main():
    cluster = acsylla.create_cluster(['localhost'], log_level='trace')
    session = await cluster.create_session(keyspace="acsylla")
    cluster.set_log_level('info')
    await session.close()

asyncio.run(main())
```

#### Set callback for capture log messages

```python
import asyncio
import acsylla

def on_log_message(msg):
    print(msg.time_ms, 
          msg.log_level, 
          msg.file, 
          msg.line, 
          msg.function, 
          msg.message)

async def main():
    cluster = acsylla.create_cluster(['localhost'], 
                                     log_level='debug', 
                                     logging_callback=on_log_message)
    session = await cluster.create_session(keyspace="acsylla")
    await session.close()

asyncio.run(main())
```

### Execution profiles

```python
import asyncio
import acsylla

async def main():
    cluster = acsylla.create_cluster(['localhost'])
    cluster.create_execution_profile(
        'test_profile',
        request_timeout=200,
        load_balance_round_robin=True,
        whitelist_hosts='localhost',
        retry_policy='default',
        retry_policy_logging=True,
    )    
    session = await cluster.create_session(keyspace="acsylla")
    # For statement
    statement = acsylla.create_statement("SELECT id, value FROM test WHERE id=100", execution_profile="test_profile")
    # or 
    statement.set_execution_profile('statement')
    await session.execute(statement)
    # For prepared statement
    prepared = await session.create_prepared("SELECT id, value FROM test")
    statement = prepared.bind(execution_profile='test_profile')
    # or 
    statement.set_execution_profile('test_profile')
    await session.execute(statement)
    # For batch
    batch = acsylla.create_batch(execution_profile="test_profile")
    # or 
    batch.set_execution_profile("test_profile")
    await session.close()

asyncio.run(main())
```

### Tracing

```python
import acsylla
import asyncio


async def pint_tracing_result(session, tracing_id):
    print('*' * 10, tracing_id, '*' * 10)
    statement = acsylla.create_statement(
        "SELECT * FROM system_traces.sessions WHERE session_id = ?", 1)
    statement.bind(0, tracing_id)
    result = await session.execute(statement)
    for row in result:
        print("\n".join([f"\033[1m{k}:\033[0m {v}" for k, v in list(row)]))


async def tracing_example():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session()
    # Statement tracing
    statement = acsylla.create_statement(
        "SELECT release_version FROM system.local")
    statement.set_tracing(True)
    result = await session.execute(statement)
    await pint_tracing_result(session, result.tracing_id)
    # Batch tracing
    batch_statement1 = acsylla.create_statement(
        "INSERT INTO acsylla.test (id, value) VALUES (1, 1)")
    batch_statement2 = acsylla.create_statement(
        "INSERT INTO acsylla.test (id, value) VALUES (2, 2)")
    batch = acsylla.create_batch_logged()
    batch.add_statement(batch_statement1)
    batch.add_statement(batch_statement2)
    batch.set_tracing(True)
    result = await session.execute_batch(batch)
    await pint_tracing_result(session, result.tracing_id)


asyncio.run(tracing_example())
```

## Developing

For developing you must clone the respository and first compile the CPP Cassandra driver, please
follow the [instructions](https://docs.datastax.com/en/developer/cpp-driver/2.6/topics/building/>)
for installing any dependency that you would need for compiling the driver:

> **_NOTE:_**
    The driver depends on `libuv` and `openssl`. To install on Mac OS X, do `brew install libuv`
    and `brew install openssl` respectively. Additionally, you may need to export openssl lib
    locations: `export LDFLAGS="-L/usr/local/opt/openssl/lib"`
    and `export CPPFLAGS="-I/usr/local/opt/openssl/include"`.


```bash
git clone git@github.com:acsylla/acsylla.git
make install-driver
```

Set up the environment and compile the package using the following commands:

```bash
python -m venv venv
source venv/bin/activate
make compile
make install-dev
```

And finally run the tests:

```bash
make cert
docker-compose up -d
make test
```
