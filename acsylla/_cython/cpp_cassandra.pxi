ctypedef int cass_int32_t
ctypedef float cass_float_t
ctypedef unsigned char cass_byte_t

cdef extern from "cassandra.h":
  ctypedef enum cass_bool_t:
    cass_false = 0
    cass_true = 1

  cdef enum:
    CASS_UUID_STRING_LENGTH

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
    CASS_PROTOCOL_VERSION_V1 = 1
    CASS_PROTOCOL_VERSION_V2 = 2
    CASS_PROTOCOL_VERSION_V3 = 3
    CASS_PROTOCOL_VERSION_V4 = 4
    CASS_PROTOCOL_VERSION_V5 = 5

  ctypedef enum CassBatchType:
    CASS_BATCH_TYPE_LOGGED
    CASS_BATCH_TYPE_UNLOGGED
    CASS_BATCH_TYPE_COUNTER

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

  ctypedef void (*CassFutureCallback)(CassFuture* future, void* data)

  CassCluster* cass_cluster_new()
  void cass_cluster_free(CassCluster* cluster)
  CassError cass_cluster_set_contact_points_n(CassCluster* cluster, const char* contact_points, size_t contat_points_length)
  CassError cass_cluster_set_protocol_version(CassCluster* cluster, int protocol_version)


  CassSession* cass_session_new()
  void cass_session_free(CassSession* session)
  CassFuture* cass_session_connect(CassSession* session, const CassCluster* cluster)
  CassFuture* cass_session_connect_keyspace_n(CassSession* session,const CassCluster* cluster, const char* keyspace, size_t keyspace_length)
  CassFuture* cass_session_execute(CassSession * session, const CassStatement* statement)
  CassFuture* cass_session_prepare_n(CassSession* session, const char* query, size_t query_length)
  CassFuture* cass_session_execute_batch(CassSession* session, const CassBatch* batch)
  CassFuture* cass_session_close(CassSession* session)

  CassStatement* cass_statement_new_n(const char* query, size_t query_length, size_t parameter_count)
  CassError cass_statement_bind_null(CassStatement* statement, size_t index)
  CassError cass_statement_bind_int32(CassStatement* statement, size_t index, cass_int32_t value)
  CassError cass_statement_bind_float(CassStatement* statement, size_t index, cass_float_t value)
  CassError cass_statement_bind_bool(CassStatement* statement, size_t index, cass_bool_t value)
  CassError cass_statement_bind_string_n(CassStatement* statement, size_t index, const char* value, size_t value_length)
  CassError cass_statement_bind_bytes(CassStatement* statement, size_t index, const cass_byte_t* value, size_t value_length)
  CassError cass_statement_bind_uuid(CassStatement* statement, size_t index, CassUuid value)
  CassError cass_statement_bind_bytes_by_name_n(CassStatement* statement, const char* name, size_t name_length, const cass_byte_t* value, size_t value_size)
  CassError cass_statement_bind_string_by_name_n(CassStatement* statement, const char* name, size_t name_length, const char* value, size_t value_length)
  CassError cass_statement_bind_bool_by_name_n(CassStatement* statement, const char* name, size_t name_length, cass_bool_t value)
  CassError cass_statement_bind_float_by_name_n(CassStatement* statement, const char* name, size_t name_length, cass_float_t value)
  CassError cass_statement_bind_int32_by_name_n(CassStatement* statement, const char* name, size_t name_length, cass_int32_t value)
  CassError cass_statement_bind_null_by_name_n(CassStatement* statement, const char* name, size_t name_length)
  CassError cass_statement_bind_uuid_by_name_n(CassStatement* statement, const char* name, size_t name_length, CassUuid value)
  CassError cass_statement_bind_uuid_by_name(CassStatement* statement, const char* name, CassUuid value)
  CassError cass_statement_set_paging_size(CassStatement* statement, int page_size)
  CassError cass_statement_set_paging_state_token(CassStatement* statement, const char* paging_state, size_t paging_state_size)

  void cass_statement_free(CassStatement* statement)

  void cass_future_free(CassFuture* future)
  CassError cass_future_error_code(CassFuture* future)
  CassError cass_future_set_callback(CassFuture* future, CassFutureCallback callback, void* data)
  CassErrorResult* cass_future_get_error_result(CassFuture* future)
  CassResult* cass_future_get_result(CassFuture* future)
  const CassPrepared* cass_future_get_prepared(CassFuture* future)

  CassError cass_error_result_code(CassErrorResult* error_result)
  void cass_error_result_free(CassErrorResult* error_result)

  size_t cass_result_row_count(CassResult* result)
  size_t cass_result_column_count(CassResult* result)
  CassRow* cass_result_first_row(CassResult* result)
  CassIterator* cass_iterator_from_result(const CassResult* result)
  cass_bool_t cass_result_has_more_pages(const CassResult* result)
  CassError cass_result_paging_state_token(const CassResult* result, const char** paging_state, size_t* paging_state_size)
  void cass_result_free(CassResult* result)

  const CassValue* cass_row_get_column_by_name(const CassRow* row, const char* name)

  CassError cass_value_get_int32(const CassValue* value, cass_int32_t * output)
  CassError cass_value_get_float(const CassValue* value, cass_float_t* output)
  CassError cass_value_get_bool(const CassValue* value, cass_bool_t* output)
  CassError cass_value_get_string(const CassValue* value, const char** output, size_t* output_size)
  CassError cass_value_get_bytes(const CassValue* value, const cass_byte_t** output, size_t* output_size)
  CassError cass_value_get_bytes(const CassValue* value, const cass_byte_t** output, size_t* output_size)
  CassError cass_value_get_uuid(const CassValue* value, CassUuid* output)
  CassRow* cass_iterator_get_row(const CassIterator* iterator)
  cass_bool_t cass_iterator_next(CassIterator* iterator)
  void cass_iterator_free(CassIterator* iterator)

  CassStatement* cass_prepared_bind(const CassPrepared* prepared)
  void cass_prepared_free(const CassPrepared* prepared)


  CassBatch* cass_batch_new(CassBatchType type)
  CassError cass_batch_add_statement(CassBatch* batch, CassStatement* statement)
  void cass_batch_free(CassBatch* cass_batch)

  CassError cass_uuid_from_string(const char* str, CassUuid* output)
  void cass_uuid_string(CassUuid uuid, char* output)
