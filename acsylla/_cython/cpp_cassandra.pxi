cdef extern from "Python.h":
    void Py_INCREF(object o)
    void Py_DECREF(object o)

cdef extern from "stdint.h":
  ctypedef   signed char  int8_t
  ctypedef   signed short int16_t
  ctypedef   signed int   int32_t
  ctypedef   signed long  int64_t
  ctypedef unsigned char  uint8_t
  ctypedef unsigned short uint16_t
  ctypedef unsigned int   uint32_t
  ctypedef unsigned long  uint64_t

ctypedef float cass_float_t
ctypedef double cass_double_t

ctypedef int8_t cass_int8_t
ctypedef uint8_t cass_uint8_t

ctypedef int16_t cass_int16_t
ctypedef uint16_t cass_uint16_t

ctypedef int32_t cass_int32_t
ctypedef uint32_t cass_uint32_t

ctypedef int64_t cass_int64_t
ctypedef uint64_t cass_uint64_t

ctypedef cass_uint8_t cass_byte_t
ctypedef cass_uint64_t cass_duration_t

cdef extern from "cassandra.h":
  cdef enum:
    CASS_INET_STRING_LENGTH

  ctypedef enum cass_bool_t:
    cass_false = 0
    cass_true = 1

  cdef enum:
    CASS_UUID_STRING_LENGTH

  ctypedef enum CassConsistency:
    CASS_CONSISTENCY_UNKNOWN
    CASS_CONSISTENCY_ANY
    CASS_CONSISTENCY_ONE
    CASS_CONSISTENCY_TWO
    CASS_CONSISTENCY_THREE
    CASS_CONSISTENCY_QUORUM
    CASS_CONSISTENCY_ALL
    CASS_CONSISTENCY_LOCAL_QUORUM
    CASS_CONSISTENCY_EACH_QUORUM
    CASS_CONSISTENCY_SERIAL
    CASS_CONSISTENCY_LOCAL_SERIAL
    CASS_CONSISTENCY_LOCAL_ONE

  ctypedef enum CassError:
    CASS_OK
    CASS_ERROR_LIB_BAD_PARAMS
    CASS_ERROR_LIB_NO_STREAMS
    CASS_ERROR_LIB_UNABLE_TO_INIT
    CASS_ERROR_LIB_MESSAGE_ENCODE
    CASS_ERROR_LIB_HOST_RESOLUTION
    CASS_ERROR_LIB_UNEXPECTED_RESPONSE
    CASS_ERROR_LIB_REQUEST_QUEUE_FULL
    CASS_ERROR_LIB_NO_AVAILABLE_IO_THREAD
    CASS_ERROR_LIB_WRITE_ERROR
    CASS_ERROR_LIB_NO_HOSTS_AVAILABLE
    CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS
    CASS_ERROR_LIB_INVALID_ITEM_COUNT
    CASS_ERROR_LIB_INVALID_VALUE_TYPE
    CASS_ERROR_LIB_REQUEST_TIMED_OUT
    CASS_ERROR_LIB_UNABLE_TO_SET_KEYSPACE
    CASS_ERROR_LIB_CALLBACK_ALREADY_SET
    CASS_ERROR_LIB_INVALID_STATEMENT_TYPE
    CASS_ERROR_LIB_NAME_DOES_NOT_EXIST
    CASS_ERROR_LIB_UNABLE_TO_DETERMINE_PROTOCOL
    CASS_ERROR_LIB_NULL_VALUE
    CASS_ERROR_LIB_NOT_IMPLEMENTED
    CASS_ERROR_LIB_UNABLE_TO_CONNECT
    CASS_ERROR_LIB_UNABLE_TO_CLOSE
    CASS_ERROR_LIB_NO_PAGING_STATE
    CASS_ERROR_LIB_PARAMETER_UNSET
    CASS_ERROR_LIB_INVALID_ERROR_RESULT_TYPE
    CASS_ERROR_LIB_INVALID_FUTURE_TYPE
    CASS_ERROR_LIB_INTERNAL_ERROR
    CASS_ERROR_LIB_INVALID_CUSTOM_TYPE
    CASS_ERROR_LIB_INVALID_DATA
    CASS_ERROR_LIB_NOT_ENOUGH_DATA
    CASS_ERROR_LIB_INVALID_STATE
    CASS_ERROR_LIB_NO_CUSTOM_PAYLOAD
    CASS_ERROR_LIB_EXECUTION_PROFILE_INVALID
    CASS_ERROR_LIB_NO_TRACING_ID
    CASS_ERROR_SERVER_SERVER_ERROR
    CASS_ERROR_SERVER_PROTOCOL_ERROR
    CASS_ERROR_SERVER_BAD_CREDENTIALS
    CASS_ERROR_SERVER_UNAVAILABLE
    CASS_ERROR_SERVER_OVERLOADED
    CASS_ERROR_SERVER_IS_BOOTSTRAPPING
    CASS_ERROR_SERVER_TRUNCATE_ERROR
    CASS_ERROR_SERVER_WRITE_TIMEOUT
    CASS_ERROR_SERVER_READ_TIMEOUT
    CASS_ERROR_SERVER_READ_FAILURE
    CASS_ERROR_SERVER_FUNCTION_FAILURE
    CASS_ERROR_SERVER_WRITE_FAILURE
    CASS_ERROR_SERVER_SYNTAX_ERROR
    CASS_ERROR_SERVER_UNAUTHORIZED
    CASS_ERROR_SERVER_INVALID_QUERY
    CASS_ERROR_SERVER_CONFIG_ERROR
    CASS_ERROR_SERVER_ALREADY_EXISTS
    CASS_ERROR_SERVER_UNPREPARED
    CASS_ERROR_SSL_INVALID_CERT
    CASS_ERROR_SSL_INVALID_PRIVATE_KEY
    CASS_ERROR_SSL_NO_PEER_CERT
    CASS_ERROR_SSL_INVALID_PEER_CERT
    CASS_ERROR_SSL_IDENTITY_MISMATCH
    CASS_ERROR_SSL_PROTOCOL_ERROR
    CASS_ERROR_SSL_CLOSED

  ctypedef enum CassProtocolVersion:
    CASS_PROTOCOL_VERSION_V1
    CASS_PROTOCOL_VERSION_V2
    CASS_PROTOCOL_VERSION_V3
    CASS_PROTOCOL_VERSION_V4
    CASS_PROTOCOL_VERSION_V5
    CASS_PROTOCOL_VERSION_DSEV1
    CASS_PROTOCOL_VERSION_DSEV2

  ctypedef enum CassBatchType:
    CASS_BATCH_TYPE_LOGGED
    CASS_BATCH_TYPE_UNLOGGED
    CASS_BATCH_TYPE_COUNTER

  ctypedef enum CassValueType:
    CASS_VALUE_TYPE_UNKNOWN 
    CASS_VALUE_TYPE_CUSTOM
    CASS_VALUE_TYPE_ASCII
    CASS_VALUE_TYPE_BIGINT
    CASS_VALUE_TYPE_BLOB
    CASS_VALUE_TYPE_BOOLEAN
    CASS_VALUE_TYPE_COUNTER
    CASS_VALUE_TYPE_DECIMAL
    CASS_VALUE_TYPE_DOUBLE
    CASS_VALUE_TYPE_FLOAT
    CASS_VALUE_TYPE_INT
    CASS_VALUE_TYPE_TEXT
    CASS_VALUE_TYPE_TIMESTAMP
    CASS_VALUE_TYPE_UUID
    CASS_VALUE_TYPE_VARCHAR
    CASS_VALUE_TYPE_VARINT
    CASS_VALUE_TYPE_TIMEUUID
    CASS_VALUE_TYPE_INET
    CASS_VALUE_TYPE_DATE
    CASS_VALUE_TYPE_TIME
    CASS_VALUE_TYPE_SMALL_INT
    CASS_VALUE_TYPE_TINY_INT
    CASS_VALUE_TYPE_DURATION
    CASS_VALUE_TYPE_LIST
    CASS_VALUE_TYPE_MAP
    CASS_VALUE_TYPE_SET
    CASS_VALUE_TYPE_UDT
    CASS_VALUE_TYPE_TUPLE

  ctypedef enum CassCollectionType:
    CASS_COLLECTION_TYPE_LIST
    CASS_COLLECTION_TYPE_MAP
    CASS_COLLECTION_TYPE_SET

  ctypedef enum CassSslVerifyFlags:
    CASS_SSL_VERIFY_NONE
    CASS_SSL_VERIFY_PEER_CERT
    CASS_SSL_VERIFY_PEER_IDENTITY
    CASS_SSL_VERIFY_PEER_IDENTITY_DNS

  ctypedef enum CassColumnType:
    CASS_COLUMN_TYPE_REGULAR
    CASS_COLUMN_TYPE_PARTITION_KEY
    CASS_COLUMN_TYPE_CLUSTERING_KEY
    CASS_COLUMN_TYPE_STATIC
    CASS_COLUMN_TYPE_COMPACT_VALUE

  ctypedef enum CassIndexType:
    CASS_INDEX_TYPE_UNKNOWN
    CASS_INDEX_TYPE_KEYS
    CASS_INDEX_TYPE_CUSTOM
    CASS_INDEX_TYPE_COMPOSITES

  ctypedef struct CassSsl:
    pass

  ctypedef struct CassCluster:
    pass

  ctypedef struct CassSession:
    pass

  ctypedef struct CassFuture:
    pass

  ctypedef struct CassPrepared:
    pass

  ctypedef struct CassStatement:
    pass

  ctypedef struct CassErrorResult:
    pass

  ctypedef struct CassResult:
    pass

  ctypedef struct CassRow:
    pass

  ctypedef struct CassValue:
    pass

  ctypedef struct CassIterator:
    pass

  ctypedef struct CassBatch:
    pass

  ctypedef struct CassUuid:
    pass

  ctypedef struct CassInet:
    pass

  ctypedef struct CassDataType:
    pass

  ctypedef struct CassCollection:
    pass

  ctypedef struct CassUserType:
    pass

  ctypedef struct CassTuple:
    pass

  ctypedef struct CassSchemaMeta:
    pass

  ctypedef struct CassKeyspaceMeta:
    pass

  ctypedef struct CassTableMeta:
    pass

  ctypedef struct CassIndexMeta:
    pass

  ctypedef struct CassColumnMeta:
    pass

  ctypedef struct CassMaterializedViewMeta:
    pass

  ctypedef struct CassFunctionMeta:
    pass

  ctypedef struct CassAggregateMeta:
    pass

  ctypedef struct CassTimestampGen:
    pass

  ctypedef struct CassVersion:
    int major_version
    int minor_version
    int patch_version

  ctypedef struct _requests:
    cass_uint64_t min
    cass_uint64_t max
    cass_uint64_t mean
    cass_uint64_t stddev
    cass_uint64_t median
    cass_uint64_t percentile_75th
    cass_uint64_t percentile_95th
    cass_uint64_t percentile_98th
    cass_uint64_t percentile_99th
    cass_uint64_t percentile_999th
    cass_double_t mean_rate
    cass_double_t one_minute_rate
    cass_double_t five_minute_rate
    cass_double_t fifteen_minute_rate

  ctypedef struct _stats:
    cass_uint64_t total_connections
    cass_uint64_t _deprecated_available_connections
    cass_uint64_t _deprecated_exceeded_pending_requests_water_mark
    cass_uint64_t _deprecated_exceeded_write_bytes_water_mark

  ctypedef struct _errors:
    cass_uint64_t connection_timeouts
    cass_uint64_t _deprecated_pending_request_timeouts
    cass_uint64_t request_timeouts

  ctypedef struct CassMetrics:
    _requests requests
    _stats stats
    _errors errors

  ctypedef struct CassSpeculativeExecutionMetrics:
    cass_uint64_t min
    cass_uint64_t max
    cass_uint64_t mean
    cass_uint64_t stddev
    cass_uint64_t median
    cass_uint64_t percentile_75th
    cass_uint64_t percentile_95th
    cass_uint64_t percentile_98th
    cass_uint64_t percentile_99th
    cass_uint64_t percentile_999th
    cass_uint64_t count
    cass_double_t percentage

  ctypedef enum CassHostListenerEvent:
    CASS_HOST_LISTENER_EVENT_UP
    CASS_HOST_LISTENER_EVENT_DOWN
    CASS_HOST_LISTENER_EVENT_ADD
    CASS_HOST_LISTENER_EVENT_REMOVE

  ctypedef enum CassLogLevel:
    CASS_LOG_DISABLED
    CASS_LOG_CRITICAL
    CASS_LOG_ERROR
    CASS_LOG_WARN
    CASS_LOG_INFO
    CASS_LOG_DEBUG
    CASS_LOG_TRACE

  ctypedef struct CassLogMessage:
    cass_uint64_t time_ms
    CassLogLevel severity
    const char* file
    int line
    const char* function
    const char* message

  ctypedef void (*CassFutureCallback)(CassFuture* future, void* data)
  ctypedef void (*CassLogCallback)(const CassLogMessage* message, void* data)
  ctypedef void (*CassHostListenerCallback)(CassHostListenerEvent event, const CassInet address, void* data)

  ctypedef struct CassExecProfile:
    pass

  ctypedef struct CassRetryPolicy:
    pass

  void cass_log_set_level(CassLogLevel log_level)
  void cass_log_set_callback(CassLogCallback callback, void* data)
  const char* cass_log_level_string(CassLogLevel log_level)

  CassCluster* cass_cluster_new()
  void cass_cluster_free(CassCluster* cluster)
  CassError cass_cluster_set_contact_points(CassCluster * cluster, const char * contact_points)
  CassError cass_cluster_set_port(CassCluster* cluster, int port)
  CassError cass_cluster_set_local_address(CassCluster * cluster, const char * name)
  CassError cass_cluster_set_protocol_version(CassCluster* cluster, int protocol_version)
  CassError cass_cluster_set_use_beta_protocol_version(CassCluster* cluster, cass_bool_t enable)
  CassError cass_cluster_set_consistency(CassCluster* cluster, CassConsistency consistency)
  CassError cass_cluster_set_serial_consistency(CassCluster * cluster, CassConsistency consistency)
  CassError cass_cluster_set_num_threads_io(CassCluster * cluster, unsigned num_threads)
  CassError cass_cluster_set_queue_size_io(CassCluster* cluster, unsigned queue_size)
  CassError cass_cluster_set_core_connections_per_host(CassCluster * cluster, unsigned num_connections)
  void cass_cluster_set_constant_reconnect(CassCluster * cluster, cass_uint64_t delay_ms)
  CassError cass_cluster_set_exponential_reconnect(CassCluster * cluster, cass_uint64_t base_delay_ms, cass_uint64_t max_delay_ms)
  CassError cass_cluster_set_new_request_ratio(CassCluster * cluster, cass_int32_t ratio)
  CassError cass_cluster_set_coalesce_delay(CassCluster * cluster, cass_int64_t delay_us)
  void cass_cluster_set_connect_timeout(CassCluster* cluster, unsigned timeout_ms)
  void cass_cluster_set_request_timeout(CassCluster* cluster, unsigned timeout_ms)
  void cass_cluster_set_resolve_timeout(CassCluster* cluster, unsigned timeout_ms)
  void cass_cluster_set_max_schema_wait_time(CassCluster * cluster, unsigned wait_time_ms)
  void cass_cluster_set_tracing_max_wait_time(CassCluster * cluster, unsigned max_wait_time_ms)
  void cass_cluster_set_tracing_retry_wait_time(CassCluster * cluster, unsigned retry_wait_time_ms)
  void cass_cluster_set_tracing_consistency(CassCluster * cluster, CassConsistency consistency)
  void cass_cluster_set_credentials(CassCluster* cluster, const char* username, const char* password)
  void cass_cluster_set_load_balance_round_robin(CassCluster * cluster)
  CassError cass_cluster_set_load_balance_dc_aware(CassCluster * cluster, const char * local_dc, unsigned used_hosts_per_remote_dc, cass_bool_t allow_remote_dcs_for_local_cl)
  void cass_cluster_set_token_aware_routing(CassCluster * cluster, cass_bool_t enabled)
  CassError cass_cluster_set_local_port_range(CassCluster * cluster, int lo, int hi);
  void cass_cluster_set_token_aware_routing_shuffle_replicas(CassCluster * cluster, cass_bool_t enabled)
  void cass_cluster_set_latency_aware_routing(CassCluster * cluster, cass_bool_t enabled)
  void cass_cluster_set_latency_aware_routing_settings(CassCluster * cluster,
                                                       cass_double_t exclusion_threshold,
                                                       cass_uint64_t scale_ms,
                                                       cass_uint64_t retry_period_ms,
                                                       cass_uint64_t update_rate_ms,
                                                       cass_uint64_t min_measured)
  void cass_cluster_set_whitelist_filtering(CassCluster* cluster, const char* hosts)
  void cass_cluster_set_blacklist_filtering(CassCluster * cluster, const char * hosts)
  void cass_cluster_set_whitelist_dc_filtering(CassCluster * cluster, const char * dcs)
  void cass_cluster_set_blacklist_dc_filtering(CassCluster * cluster, const char * dcs)
  void cass_cluster_set_tcp_nodelay(CassCluster * cluster, cass_bool_t enabled)
  void cass_cluster_set_tcp_keepalive(CassCluster * cluster, cass_bool_t enabled, unsigned delay_secs)
  void cass_cluster_set_timestamp_gen(CassCluster * cluster, CassTimestampGen * timestamp_gen)
  void cass_cluster_set_retry_policy(CassCluster * cluster, CassRetryPolicy * retry_policy)
  void cass_cluster_set_use_schema(CassCluster * cluster, cass_bool_t enabled)
  CassError cass_cluster_set_use_hostname_resolution(CassCluster* cluster, cass_bool_t enabled)
  CassError cass_cluster_set_use_randomized_contact_points(CassCluster * cluster, cass_bool_t enabled)
  CassError cass_cluster_set_constant_speculative_execution_policy(CassCluster * cluster, cass_int64_t constant_delay_ms, int max_speculative_executions)
  CassError cass_cluster_set_no_speculative_execution_policy(CassCluster * cluster)
  CassError cass_cluster_set_max_reusable_write_objects(CassCluster * cluster, unsigned num_objects)
  CassError cass_cluster_set_prepare_on_all_hosts(CassCluster * cluster, cass_bool_t enabled)
  CassError cass_cluster_set_no_compact(CassCluster * cluster, cass_bool_t enabled)
  CassError cass_cluster_set_host_listener_callback(CassCluster * cluster, CassHostListenerCallback callback, void * data)
  void cass_cluster_set_application_version(CassCluster * cluster, const char * application_version)
  void cass_cluster_set_application_name(CassCluster * cluster, const char * application_name)
  void cass_cluster_set_client_id(CassCluster * cluster, CassUuid client_id)
  void cass_cluster_set_monitor_reporting_interval(CassCluster * cluster, unsigned interval_secs)
  void cass_cluster_set_connection_heartbeat_interval(CassCluster * cluster, unsigned interval_secs)
  void cass_cluster_set_connection_idle_timeout(CassCluster * cluster, unsigned timeout_secs)
  void cass_cluster_set_ssl(CassCluster* cluster, CassSsl * ssl)
  CassError cass_cluster_set_execution_profile(CassCluster * cluster, const char * name, CassExecProfile * profile)
  CassError cass_cluster_set_cloud_secure_connection_bundle(CassCluster * cluster, const char * path)

  CassSsl* cass_ssl_new()
  void cass_ssl_free(CassSsl * ssl)
  CassError cass_ssl_add_trusted_cert(CassSsl * ssl, const char * cert)
  void cass_ssl_set_verify_flags(CassSsl * ssl, int flags)
  CassError cass_ssl_set_cert(CassSsl * ssl, const char * cert)
  CassError cass_ssl_set_private_key(CassSsl * ssl, const char * key, const char * password)

  CassTimestampGen* cass_timestamp_gen_server_side_new()
  CassTimestampGen* cass_timestamp_gen_monotonic_new()
  void cass_timestamp_gen_free(CassTimestampGen* timestamp_gen)

  CassSession* cass_session_new()
  void cass_session_free(CassSession* session)
  CassFuture* cass_session_connect(CassSession* session, const CassCluster* cluster)
  CassFuture* cass_session_connect_keyspace_n(CassSession* session,const CassCluster* cluster, const char* keyspace, size_t keyspace_length)
  CassFuture* cass_session_execute(CassSession* session, const CassStatement* statement)
  CassFuture* cass_session_prepare_n(CassSession* session, const char* query, size_t query_length)
  CassFuture* cass_session_execute_batch(CassSession* session, const CassBatch* batch)

  CassUuid cass_session_get_client_id(CassSession* session)
  void cass_session_get_metrics(const CassSession* session, CassMetrics* output)
  void cass_session_get_speculative_execution_metrics(const CassSession * session, CassSpeculativeExecutionMetrics * output)

  CassError cass_prepared_parameter_name(const CassPrepared* prepared, size_t index,  const char** name, size_t* name_length)
  const CassDataType* cass_prepared_parameter_data_type(const CassPrepared* prepared, size_t index)
  const CassDataType* cass_prepared_parameter_data_type_by_name(const CassPrepared* prepared,const char * name)
  CassFuture* cass_session_close(CassSession* session)

  CassStatement* cass_statement_new(const char* query, size_t parameter_count)
  CassStatement* cass_statement_new_n(const char* query, size_t query_length, size_t parameter_count)
  void cass_statement_free(CassStatement * statement)
  CassError cass_statement_add_key_index(CassStatement * statement, size_t index)
  CassError cass_statement_reset_parameters(CassStatement * statement, size_t count)
  CassError cass_statement_set_paging_size(CassStatement* statement, int page_size)
  CassError cass_statement_set_paging_state_token(CassStatement* statement, const char* paging_state, size_t paging_state_size)
  CassError cass_statement_set_consistency(CassStatement* statement, CassConsistency consistency)
  CassError cass_statement_set_serial_consistency(CassStatement * statement, CassConsistency serial_consistency)
  CassError cass_statement_set_timestamp(CassStatement * statement, cass_int64_t timestamp)
  CassError cass_statement_set_request_timeout(CassStatement* statement, cass_uint64_t timeout_ms)
  CassError cass_statement_set_is_idempotent(CassStatement * statement, cass_bool_t is_idempotent)
  CassError cass_statement_set_retry_policy(CassStatement * statement, CassRetryPolicy * retry_policy)
  CassError cass_statement_set_tracing(CassStatement * statement, cass_bool_t enabled)
  CassError cass_statement_set_host(CassStatement * statement, const char * host, int port)
  CassError cass_statement_set_execution_profile(CassStatement * statement, const char * name)
  CassError cass_statement_bind_null(CassStatement* statement, size_t index)
  CassError cass_statement_bind_int8(CassStatement* statement, size_t index,  cass_int8_t value)
  CassError cass_statement_bind_int16(CassStatement* statement, size_t index,  cass_int16_t value)
  CassError cass_statement_bind_int32(CassStatement* statement, size_t index,  cass_int32_t value)
  CassError cass_statement_bind_int64(CassStatement* statement, size_t index,  cass_int64_t value)
  CassError cass_statement_bind_uint32(CassStatement* statement, size_t index,  cass_uint32_t value)
  CassError cass_statement_bind_float(CassStatement* statement, size_t index,  cass_float_t value)
  CassError cass_statement_bind_double(CassStatement* statement, size_t index,  cass_double_t value)
  CassError cass_statement_bind_decimal(CassStatement * statement, size_t index,  const cass_byte_t* varint, size_t varint_size, cass_int32_t scale)
  CassError cass_statement_bind_bool(CassStatement* statement, size_t index,  cass_bool_t value)
  CassError cass_statement_bind_string(CassStatement* statement, size_t index,  const char* value)
  CassError cass_statement_bind_string_n(CassStatement* statement, size_t index,  const char* value, size_t value_length)
  CassError cass_statement_bind_bytes(CassStatement* statement, size_t index,  const cass_byte_t* value, size_t value_length)
  CassError cass_statement_bind_uuid(CassStatement* statement, size_t index,  CassUuid value)
  CassError cass_statement_bind_inet(CassStatement* statement, size_t index,  CassInet value)
  CassError cass_statement_bind_collection(CassStatement* statement, size_t index,  const CassCollection * collection)
  CassError cass_statement_bind_tuple(CassStatement* statement, size_t index,  const CassTuple * tuple)
  CassError cass_statement_bind_user_type(CassStatement* statement, size_t index,  const CassUserType * user_type)
  CassError cass_statement_bind_duration_by_name(CassStatement* statement, const char * name, cass_int32_t months, cass_int32_t days, cass_int64_t nanos)
  CassError cass_statement_bind_duration(CassStatement* statement, size_t index,  cass_int32_t months, cass_int32_t days, cass_int64_t nanos)
  CassError cass_statement_bind_bytes_by_name(CassStatement* statement, const char* name, const cass_byte_t* value, size_t value_size)
  CassError cass_statement_bind_bytes_by_name_n(CassStatement* statement, const char* name, size_t name_length, const cass_byte_t* value, size_t value_size)
  CassError cass_statement_bind_string_by_name(CassStatement* statement, const char* name, const char* value)
  CassError cass_statement_bind_string_by_name_n(CassStatement* statement, const char* name, size_t name_length, const char* value, size_t value_length)
  CassError cass_statement_bind_float_by_name(CassStatement* statement, const char* name, cass_float_t value)
  CassError cass_statement_bind_float_by_name_n(CassStatement* statement, const char* name, size_t name_length, cass_float_t value)
  CassError cass_statement_bind_double_by_name(CassStatement* statement, const char* name, cass_double_t value)
  CassError cass_statement_bind_decimal_by_name(CassStatement * statement, const char* name, const cass_byte_t* varint, size_t varint_size, cass_int32_t scale)
  CassError cass_statement_bind_bool_by_name(CassStatement* statement, const char* name, cass_bool_t value)
  CassError cass_statement_bind_bool_by_name_n(CassStatement* statement, const char* name, size_t name_length, cass_bool_t value)
  CassError cass_statement_bind_int8_by_name(CassStatement* statement, const char* name, cass_int8_t value)
  CassError cass_statement_bind_int16_by_name(CassStatement* statement, const char* name, cass_int16_t value)
  CassError cass_statement_bind_int32_by_name(CassStatement* statement, const char* name, cass_int32_t value)
  CassError cass_statement_bind_int32_by_name_n(CassStatement* statement, const char* name, size_t name_length, cass_int32_t value)
  CassError cass_statement_bind_int64_by_name(CassStatement* statement, const char* name, cass_int64_t value)
  CassError cass_statement_bind_int64_by_name_n(CassStatement* statement, const char* name, size_t name_length, cass_int64_t value)
  CassError cass_statement_bind_uint32_by_name(CassStatement* statement, const char * name, cass_uint32_t value)
  CassError cass_statement_bind_null_by_name(CassStatement* statement, const char* name)
  CassError cass_statement_bind_null_by_name_n(CassStatement* statement, const char* name, size_t name_length)
  CassError cass_statement_bind_uuid_by_name(CassStatement* statement, const char* name, CassUuid value)
  CassError cass_statement_bind_uuid_by_name_n(CassStatement* statement, const char* name, size_t name_length, CassUuid value)
  CassError cass_statement_bind_inet_by_name(CassStatement* statement, const char* name, CassInet value)
  CassError cass_statement_bind_collection_by_name(CassStatement* statement, const char * name, const CassCollection * collection)
  CassError cass_statement_bind_tuple_by_name(CassStatement * statement, const char * name, const CassTuple * tuple)
  CassError cass_statement_bind_user_type_by_name(CassStatement * statement, const char * name, const CassUserType * user_type)


  void cass_future_free(CassFuture* future)
  CassError cass_future_error_code(CassFuture* future)
  CassError cass_future_set_callback(CassFuture* future, CassFutureCallback callback, void* data)
  CassErrorResult* cass_future_get_error_result(CassFuture* future)
  CassResult* cass_future_get_result(CassFuture* future)
  const CassPrepared* cass_future_get_prepared(CassFuture* future)
  CassError cass_future_tracing_id(CassFuture * future, CassUuid * tracing_id)
  void cass_future_error_message(CassFuture * future, const char** message, size_t * message_length)

  CassError cass_error_result_code(CassErrorResult* error_result)
  void cass_error_result_free(CassErrorResult* error_result)
  const char * cass_error_desc(CassError error)
  size_t cass_result_row_count(CassResult* result)
  size_t cass_result_column_count(CassResult* result)
  CassRow* cass_result_first_row(CassResult* result)
  CassIterator* cass_iterator_from_result(const CassResult* result)
  cass_bool_t cass_result_has_more_pages(const CassResult* result)
  CassError cass_result_paging_state_token(const CassResult* result, const char** paging_state, size_t* paging_state_size)
  CassError cass_result_column_name(const CassResult* result, size_t index,  const char** name,size_t* name_length)
  void cass_result_free(CassResult* result)

  CassValueType cass_data_type_type(const CassDataType* data_type)
  const CassValue* cass_row_get_column(const CassRow* row, size_t index)
  const CassValue* cass_row_get_column_by_name(const CassRow* row, const char* name)

  CassIterator* cass_iterator_from_map(const CassValue* value)
  CassValue* cass_iterator_get_map_key(const CassIterator* iterator)
  CassValue* cass_iterator_get_map_value(const CassIterator* iterator)

  CassIterator* cass_iterator_from_collection(const CassValue* value)
  CassIterator* cass_iterator_from_tuple(const CassValue* value)

  CassIterator* cass_iterator_fields_from_user_type(const CassValue* value)
  CassError cass_iterator_get_user_type_field_name(const CassIterator* iterator, const char** name, size_t* name_length)
  CassValue* cass_iterator_get_user_type_field_value(const CassIterator* iterator)

  cass_bool_t cass_value_is_null(const CassValue * value)

  CassValueType cass_value_type(const CassValue* value)

  CassError cass_value_get_int8(const CassValue* value, cass_int8_t* output)
  CassError cass_value_get_int16(const CassValue* value, cass_int16_t* output)
  CassError cass_value_get_int32(const CassValue* value, cass_int32_t* output)
  CassError cass_value_get_int64(const CassValue* value, cass_int64_t* output)
  CassError cass_value_get_uint32(const CassValue* value, cass_uint32_t* output)
  CassError cass_value_get_float(const CassValue* value, cass_float_t* output)
  CassError cass_value_get_double(const CassValue* value, cass_double_t* output)
  CassError cass_value_get_decimal(const CassValue* value, const cass_byte_t** varint, size_t* varint_size, cass_int32_t* scale)
  CassError cass_value_get_bool(const CassValue* value, cass_bool_t* output)
  CassError cass_value_get_string(const CassValue* value, const char** output, size_t* output_size)
  CassError cass_value_get_bytes(const CassValue* value, const cass_byte_t** output, size_t* output_size)
  CassError cass_value_get_inet(const CassValue* value, CassInet* output)
  CassError cass_value_get_uuid(const CassValue* value, CassUuid* output)
  CassError cass_value_get_duration(const CassValue* value, cass_int32_t* months, cass_int32_t* days, cass_int64_t* nanos)
  CassRow* cass_iterator_get_row(const CassIterator* iterator)
  const CassValue* cass_iterator_get_value(const CassIterator* iterator)

  cass_bool_t cass_iterator_next(CassIterator* iterator)
  void cass_iterator_free(CassIterator* iterator)

  CassStatement* cass_prepared_bind(const CassPrepared* prepared)
  void cass_prepared_free(const CassPrepared* prepared)

  CassBatch* cass_batch_new(CassBatchType type)
  CassError cass_batch_set_consistency(CassBatch * batch, CassConsistency consistency)
  CassError cass_batch_set_serial_consistency(CassBatch * batch, CassConsistency serial_consistency)
  CassError cass_batch_set_timestamp(CassBatch * batch, cass_int64_t timestamp)
  CassError cass_batch_set_request_timeout(CassBatch * batch, cass_uint64_t timeout_ms)
  CassError cass_batch_set_is_idempotent(CassBatch * batch, cass_bool_t is_idempotent)
  CassError cass_batch_set_retry_policy(CassBatch * batch, CassRetryPolicy * retry_policy)
  CassError cass_batch_set_tracing(CassBatch * batch, cass_bool_t enabled)
  CassError cass_batch_set_execution_profile(CassBatch* batch, const char * name)
  CassError cass_batch_add_statement(CassBatch* batch, CassStatement* statement)
  void cass_batch_free(CassBatch* cass_batch)

  CassError cass_uuid_from_string(const char* str, CassUuid* output)
  void cass_uuid_string(CassUuid uuid, char* output)

  CassError cass_inet_from_string(const char* str, CassInet* output)
  void cass_inet_string(CassInet inet, char* output)

  cass_int64_t cass_time_from_epoch(cass_int64_t epoch_secs)
  cass_uint32_t cass_date_from_epoch(cass_int64_t epoch_secs)
  cass_int64_t cass_date_time_to_epoch(cass_uint32_t date, cass_int64_t time)

  CassCollection* cass_collection_new(CassCollectionType type, size_t item_count)
  CassCollection* cass_collection_new_from_data_type(const CassDataType* data_type, size_t item_count)

  void cass_collection_free(CassCollection* collection)
  const CassDataType* cass_collection_data_type(const CassCollection* collection)

  CassError cass_collection_append_int8(CassCollection* collection, cass_int8_t value)
  CassError cass_collection_append_int16(CassCollection* collection, cass_int16_t value)
  CassError cass_collection_append_int32(CassCollection* collection, cass_int32_t value)
  CassError cass_collection_append_uint32(CassCollection* collection, cass_uint32_t value)
  CassError cass_collection_append_int64(CassCollection* collection, cass_int64_t value)
  CassError cass_collection_append_float(CassCollection* collection, cass_float_t value)
  CassError cass_collection_append_double(CassCollection* collection, cass_double_t value)
  CassError cass_collection_append_bool(CassCollection* collection, cass_bool_t value)
  CassError cass_collection_append_string(CassCollection* collection, const char* value)
  CassError cass_collection_append_bytes(CassCollection* collection, const cass_byte_t* value, size_t value_size)
  CassError cass_collection_append_custom(CassCollection* collection, const char* class_name, const cass_byte_t* value, size_t value_size)
  CassError cass_collection_append_uuid(CassCollection* collection, CassUuid value)
  CassError cass_collection_append_inet(CassCollection* collection, CassInet value)
  CassError cass_collection_append_decimal(CassCollection* collection, const cass_byte_t* varint, size_t varint_size, cass_int32_t scale)
  CassError cass_collection_append_duration(CassCollection* collection, cass_int32_t months, cass_int32_t days, cass_int64_t nanos)
  CassError cass_collection_append_collection(CassCollection* collection, const CassCollection* value)
  CassError cass_collection_append_tuple(CassCollection* collection, const CassTuple* value)
  CassError cass_collection_append_user_type(CassCollection* collection, const CassUserType* value)

  CassTuple* cass_tuple_new(size_t item_count)
  CassTuple* cass_tuple_new_from_data_type(const CassDataType* data_type)
  void cass_tuple_free(CassTuple* tuple)

  CassError cass_tuple_set_null(CassTuple * tuple, size_t index)
  CassError cass_tuple_set_int8(CassTuple * tuple, size_t index,  cass_int8_t value)
  CassError cass_tuple_set_int16(CassTuple * tuple, size_t index,  cass_int16_t value)
  CassError cass_tuple_set_int32(CassTuple * tuple, size_t index,  cass_int32_t value)
  CassError cass_tuple_set_uint32(CassTuple * tuple, size_t index,  cass_uint32_t value)
  CassError cass_tuple_set_int64(CassTuple * tuple, size_t index,  cass_int64_t value)
  CassError cass_tuple_set_float(CassTuple * tuple, size_t index,  cass_float_t value)
  CassError cass_tuple_set_double(CassTuple * tuple, size_t index,  cass_double_t value)
  CassError cass_tuple_set_bool(CassTuple * tuple, size_t  index,  cass_bool_t value)
  CassError cass_tuple_set_string(CassTuple * tuple, size_t index,  const char * value)
  CassError cass_tuple_set_string_n(CassTuple * tuple, size_t index,  const char * value, size_t value_length)
  CassError cass_tuple_set_bytes(CassTuple * tuple, size_t index,  const cass_byte_t * value, size_t value_size)
  CassError cass_tuple_set_custom(CassTuple * tuple, size_t index,  const char * class_name, const cass_byte_t * value, size_t value_size)
  CassError cass_tuple_set_custom_n(CassTuple * tuple, size_t index,  const char * class_name, size_t class_name_length, const cass_byte_t * value, size_t value_size)
  CassError cass_tuple_set_uuid(CassTuple * tuple, size_t index,  CassUuid value)
  CassError cass_tuple_set_inet(CassTuple * tuple, size_t index,  CassInet value)
  CassError cass_tuple_set_decimal(CassTuple * tuple, size_t index,  const cass_byte_t * varint, size_t varint_size, cass_int32_t scale)
  CassError cass_tuple_set_duration(CassTuple * tuple, size_t index,  cass_int32_t months, cass_int32_t days, cass_int64_t nanos)
  CassError cass_tuple_set_collection(CassTuple * tuple, size_t index,  const CassCollection * value)
  CassError cass_tuple_set_tuple(CassTuple * tuple, size_t index,  const CassTuple * value)
  CassError cass_tuple_set_user_type(CassTuple * tuple, size_t index,  const CassUserType * value)

  CassIterator* cass_iterator_fields_from_user_type(const CassValue* value)
  CassDataType* cass_data_type_new_udt(size_t field_count)
  void cass_data_type_free(CassDataType * data_type)
  size_t cass_data_type_sub_type_count(const CassDataType * data_type)
  const CassDataType* cass_data_type_sub_data_type(const CassDataType* data_type, size_t index)
  const CassDataType* cass_data_type_sub_data_type_by_name(const CassDataType * data_type, const char * name)
  CassError cass_data_type_keyspace(const CassDataType* data_type, const char** keyspace, size_t* keyspace_length)
  CassError cass_data_type_sub_type_name(const CassDataType* data_type, size_t index, const char** name, size_t* name_length)
  CassError cass_data_type_class_name(const CassDataType* data_type, const char** class_name, size_t* class_name_length)
  cass_bool_t cass_data_type_is_frozen(const CassDataType* data_type)

  CassUserType* cass_user_type_new_from_data_type(const CassDataType * data_type)
  void cass_user_type_free(CassUserType* user_type)

  CassIterator* cass_iterator_keyspaces_from_schema_meta(const CassSchemaMeta * schema_meta)
  CassIterator* cass_iterator_fields_from_keyspace_meta(const CassKeyspaceMeta* keyspace_meta)
  CassIterator* cass_iterator_tables_from_keyspace_meta(const CassKeyspaceMeta * keyspace_meta)
  CassIterator* cass_iterator_columns_from_table_meta(const CassTableMeta* table_meta)
  CassIterator* cass_iterator_indexes_from_table_meta(const CassTableMeta* table_meta)
  CassIterator* cass_iterator_fields_from_column_meta(const CassColumnMeta* column_meta)
  CassIterator* cass_iterator_fields_from_function_meta(const CassFunctionMeta* function_meta)
  CassIterator* cass_iterator_fields_from_table_meta(const CassTableMeta* table_meta)
  CassIterator* cass_iterator_materialized_views_from_keyspace_meta(const CassKeyspaceMeta* keyspace_meta)
  CassIterator* cass_iterator_fields_from_materialized_view_meta(const CassMaterializedViewMeta* view_meta)
  CassIterator* cass_iterator_user_types_from_keyspace_meta(const CassKeyspaceMeta* keyspace_meta)
  CassIterator* cass_iterator_functions_from_keyspace_meta(const CassKeyspaceMeta* keyspace_meta)
  CassIterator* cass_iterator_aggregates_from_keyspace_meta(const CassKeyspaceMeta* keyspace_meta)
  CassIterator* cass_iterator_columns_from_materialized_view_meta(const CassMaterializedViewMeta* view_meta)
  CassIterator* cass_iterator_materialized_views_from_table_meta(const CassTableMeta* table_meta)
  CassIterator* cass_iterator_fields_from_index_meta(const CassIndexMeta* index_meta)
  CassIterator* cass_iterator_fields_from_aggregate_meta(const CassAggregateMeta* aggregate_meta)

  CassError cass_iterator_get_meta_field_name(const CassIterator* iterator, const char** name, size_t* name_length)
  const CassKeyspaceMeta* cass_iterator_get_keyspace_meta(const CassIterator * iterator)
  const CassKeyspaceMeta* cass_schema_meta_keyspace_by_name(const CassSchemaMeta* schema_meta, const char* keyspace)
  const CassSchemaMeta* cass_session_get_schema_meta(const CassSession* session)
  const CassTableMeta* cass_iterator_get_table_meta(const CassIterator * iterator)
  const CassTableMeta* cass_keyspace_meta_table_by_name(const CassKeyspaceMeta* keyspace_meta, const char* table)
  const CassColumnMeta* cass_iterator_get_column_meta(const CassIterator* iterator)
  const CassIndexMeta* cass_iterator_get_index_meta(const CassIterator* iterator)
  const CassMaterializedViewMeta* cass_iterator_get_materialized_view_meta(const CassIterator* iterator)
  const CassDataType* cass_iterator_get_user_type(const CassIterator* iterator)
  const CassFunctionMeta* cass_iterator_get_function_meta(const CassIterator* iterator)
  const CassAggregateMeta* cass_iterator_get_aggregate_meta(const CassIterator* iterator)

  CassVersion cass_schema_meta_version(const CassSchemaMeta * schema_meta)
  cass_uint32_t cass_schema_meta_snapshot_version(const CassSchemaMeta * schema_meta)
  void cass_schema_meta_free(const CassSchemaMeta* schema_meta)
  void cass_keyspace_meta_name(const CassKeyspaceMeta* keyspace_meta, const char** name, size_t* name_length)
  void cass_table_meta_name(const CassTableMeta * table_meta, const char** name, size_t * name_length)
  void cass_column_meta_name(const CassColumnMeta* column_meta, const char** name, size_t* name_length)
  void cass_index_meta_name(const CassIndexMeta* index_meta, const char** name, size_t* name_length)
  void cass_index_meta_target(const CassIndexMeta* index_meta, const char** target, size_t* target_length)
  void cass_materialized_view_meta_name(const CassMaterializedViewMeta* view_meta, const char** name, size_t* name_length)
  void cass_function_meta_name(const CassFunctionMeta* function_meta, const char** name, size_t* name_length)
  void cass_function_meta_full_name(const CassFunctionMeta* function_meta, const char** full_name, size_t* full_name_length)
  void cass_function_meta_body(const CassFunctionMeta* function_meta, const char** body, size_t* body_length)
  void cass_function_meta_language(const CassFunctionMeta* function_meta, const char** language, size_t* language_length)

  const CassDataType* cass_column_meta_data_type(const CassColumnMeta* column_meta)
  const CassTableMeta* cass_materialized_view_meta_base_table(const CassMaterializedViewMeta* view_meta)
  CassColumnType cass_column_meta_type(const CassColumnMeta* column_meta)
  CassIndexType cass_index_meta_type(const CassIndexMeta* index_meta)
  const CassValue* cass_index_meta_options(const CassIndexMeta* index_meta)
  const CassValue* cass_iterator_get_meta_field_value(const CassIterator* iterator)
  cass_bool_t cass_keyspace_meta_is_virtual(const CassKeyspaceMeta* keyspace_meta)
  cass_bool_t cass_table_meta_is_virtual(const CassTableMeta* table_meta)

  CassError cass_data_type_type_name(const CassDataType* data_type, const char** type_name, size_t* type_name_length)

  CassError cass_user_type_set_null(CassUserType* user_type, size_t index)
  CassError cass_user_type_set_null_by_name(CassUserType* user_type, const char* name)
  CassError cass_user_type_set_null_by_name_n(CassUserType* user_type, const char* name, size_t name_length)
  CassError cass_user_type_set_int8(CassUserType* user_type, size_t index,  cass_int8_t value)
  CassError cass_user_type_set_int8_by_name(CassUserType* user_type, const char* name, cass_int8_t value)
  CassError cass_user_type_set_int8_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_int8_t value)
  CassError cass_user_type_set_int16(CassUserType* user_type, size_t index,  cass_int16_t value)
  CassError cass_user_type_set_int16_by_name(CassUserType* user_type, const char* name, cass_int16_t value)
  CassError cass_user_type_set_int16_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_int16_t value)
  CassError cass_user_type_set_int32(CassUserType* user_type, size_t index,  cass_int32_t value)
  CassError cass_user_type_set_int32_by_name(CassUserType* user_type, const char* name, cass_int32_t value)
  CassError cass_user_type_set_int32_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_int32_t value)
  CassError cass_user_type_set_uint32(CassUserType* user_type, size_t index,  cass_uint32_t value)
  CassError cass_user_type_set_uint32_by_name(CassUserType* user_type, const char* name, cass_uint32_t value)
  CassError cass_user_type_set_uint32_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_uint32_t value)
  CassError cass_user_type_set_int64(CassUserType* user_type, size_t index,  cass_int64_t value)
  CassError cass_user_type_set_int64_by_name(CassUserType* user_type, const char* name, cass_int64_t value)
  CassError cass_user_type_set_int64_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_int64_t value)
  CassError cass_user_type_set_float(CassUserType* user_type, size_t index,  cass_float_t value)
  CassError cass_user_type_set_float_by_name(CassUserType* user_type, const char* name, cass_float_t value)
  CassError cass_user_type_set_float_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_float_t value)
  CassError cass_user_type_set_double(CassUserType* user_type, size_t index,  cass_double_t value)
  CassError cass_user_type_set_double_by_name(CassUserType* user_type, const char* name, cass_double_t value)
  CassError cass_user_type_set_double_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_double_t value)
  CassError cass_user_type_set_bool(CassUserType* user_type, size_t index,  cass_bool_t value)
  CassError cass_user_type_set_bool_by_name(CassUserType* user_type, const char* name, cass_bool_t value)
  CassError cass_user_type_set_bool_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_bool_t value)
  CassError cass_user_type_set_string(CassUserType* user_type, size_t index,  const char* value)
  CassError cass_user_type_set_string_n(CassUserType* user_type, size_t index,  const char* value, size_t value_length)
  CassError cass_user_type_set_string_by_name(CassUserType* user_type, const char* name, const char* value)
  CassError cass_user_type_set_string_by_name_n(CassUserType* user_type, const char* name, size_t name_length, const char* value, size_t value_length)
  CassError cass_user_type_set_bytes(CassUserType* user_type, size_t index,  const cass_byte_t* value, size_t value_size)
  CassError cass_user_type_set_bytes_by_name(CassUserType* user_type, const char* name, const cass_byte_t* value, size_t value_size);
  CassError cass_user_type_set_bytes_by_name_n(CassUserType* user_type, const char* name, size_t name_length, const cass_byte_t* value, size_t value_size)
  CassError cass_user_type_set_custom(CassUserType* user_type, size_t index,  const char* class_name, const cass_byte_t* value, size_t value_size)
  CassError cass_user_type_set_custom_n(CassUserType* user_type, size_t index,  const char* class_name, size_t class_name_length, const cass_byte_t* value, size_t value_size)
  CassError cass_user_type_set_custom_by_name(CassUserType* user_type, const char* name, const char* class_name, const cass_byte_t* value, size_t value_size)
  CassError cass_user_type_set_custom_by_name_n(CassUserType* user_type, const char* name, size_t name_length, const char* class_name, size_t class_name_length, const cass_byte_t* value, size_t value_size)
  CassError cass_user_type_set_uuid(CassUserType* user_type, size_t index,  CassUuid value)
  CassError cass_user_type_set_uuid_by_name(CassUserType* user_type, const char* name, CassUuid value)
  CassError cass_user_type_set_uuid_by_name_n(CassUserType* user_type, const char* name, size_t name_length, CassUuid value)
  CassError cass_user_type_set_inet(CassUserType* user_type, size_t index,  CassInet value)
  CassError cass_user_type_set_inet_by_name(CassUserType* user_type, const char* name, CassInet value)
  CassError cass_user_type_set_inet_by_name_n(CassUserType* user_type, const char* name, size_t name_length, CassInet value)
  CassError cass_user_type_set_decimal(CassUserType* user_type, size_t index,  const cass_byte_t* varint, size_t varint_size, int scale)
  CassError cass_user_type_set_decimal_by_name(CassUserType* user_type, const char* name, const cass_byte_t* varint, size_t varint_size, int scale)
  CassError cass_user_type_set_decimal_by_name_n(CassUserType* user_type, const char* name, size_t name_length, const cass_byte_t* varint, size_t varint_size, int scale)
  CassError cass_user_type_set_duration(CassUserType* user_type, size_t index,  cass_int32_t months, cass_int32_t days, cass_int64_t nanos)
  CassError cass_user_type_set_duration_by_name(CassUserType* user_type, const char* name, cass_int32_t months, cass_int32_t days, cass_int64_t nanos)
  CassError cass_user_type_set_duration_by_name_n(CassUserType* user_type, const char* name, size_t name_length, cass_int32_t months, cass_int32_t days, cass_int64_t nanos)
  CassError cass_user_type_set_collection(CassUserType* user_type, size_t index,  const CassCollection* value)
  CassError cass_user_type_set_collection_by_name(CassUserType* user_type, const char* name, const CassCollection* value)
  CassError cass_user_type_set_collection_by_name_n(CassUserType* user_type, const char* name, size_t name_length, const CassCollection* value)
  CassError cass_user_type_set_tuple(CassUserType* user_type, size_t index,  const CassTuple* value)
  CassError cass_user_type_set_tuple_by_name(CassUserType* user_type, const char* name, const CassTuple* value)
  CassError cass_user_type_set_tuple_by_name_n(CassUserType* user_type, const char* name, size_t name_length, const CassTuple* value)
  CassError cass_user_type_set_user_type(CassUserType* user_type, size_t index,  const CassUserType* value)
  CassError cass_user_type_set_user_type_by_name(CassUserType* user_type, const char* name, const CassUserType* value)
  CassRetryPolicy* cass_retry_policy_default_new()
  CassRetryPolicy* cass_retry_policy_fallthrough_new()
  CassRetryPolicy* cass_retry_policy_logging_new(CassRetryPolicy * child_retry_policy)
  void cass_retry_policy_free(CassRetryPolicy * policy)

  CassExecProfile* cass_execution_profile_new()
  void cass_execution_profile_free(CassExecProfile * profile)
  CassError cass_execution_profile_set_request_timeout(CassExecProfile * profile, cass_uint64_t timeout_ms)
  CassError cass_execution_profile_set_consistency(CassExecProfile * profile, CassConsistency consistency)
  CassError cass_execution_profile_set_serial_consistency(CassExecProfile * profile, CassConsistency serial_consistency)
  CassError cass_execution_profile_set_load_balance_round_robin(CassExecProfile * profile)
  CassError cass_execution_profile_set_load_balance_dc_aware(CassExecProfile* profile, const char* local_dc, unsigned used_hosts_per_remote_dc, cass_bool_t allow_remote_dcs_for_local_cl)
  CassError cass_execution_profile_set_token_aware_routing(CassExecProfile* profile, cass_bool_t enabled)
  CassError cass_execution_profile_set_token_aware_routing_shuffle_replicas(CassExecProfile* profile, cass_bool_t enabled)
  CassError cass_execution_profile_set_latency_aware_routing(CassExecProfile * profile, cass_bool_t enabled)
  CassError cass_execution_profile_set_latency_aware_routing_settings(
          CassExecProfile * profile,
          cass_double_t exclusion_threshold,
          cass_uint64_t scale_ms,
          cass_uint64_t retry_period_ms,
          cass_uint64_t update_rate_ms,
          cass_uint64_t min_measured)
  CassError cass_execution_profile_set_whitelist_filtering(CassExecProfile * profile, const char * hosts)
  CassError cass_execution_profile_set_blacklist_filtering(CassExecProfile * profile, const char * hosts)
  CassError cass_execution_profile_set_whitelist_dc_filtering(CassExecProfile * profile, const char * dcs)
  CassError cass_execution_profile_set_blacklist_dc_filtering(CassExecProfile * profile, const char * dcs)
  CassError cass_execution_profile_set_retry_policy(CassExecProfile * profile, CassRetryPolicy * retry_policy)
  CassError cass_execution_profile_set_constant_speculative_execution_policy(CassExecProfile * profile, cass_int64_t constant_delay_ms, int max_speculative_executions)

cdef extern from "dse.h":
  CassError cass_cluster_set_dse_gssapi_authenticator(CassCluster * cluster, const char * service, const char * principal)
  CassError cass_cluster_set_dse_gssapi_authenticator_proxy(CassCluster* cluster, const char* service, const char* principal, const char* authorization_id)
  CassError cass_cluster_set_dse_plaintext_authenticator(CassCluster * cluster, const char * username, const char * password)
  CassError cass_cluster_set_dse_plaintext_authenticator_proxy(CassCluster* cluster, const char* username, const char* password, const char* authorization_id)