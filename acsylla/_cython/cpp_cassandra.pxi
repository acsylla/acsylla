ctypedef int cass_int32_t
ctypedef float cass_float_t
ctypedef unsigned char cass_byte_t

cdef extern from "cassandra.h":
  ctypedef enum cass_bool_t:
    cass_false = 0
    cass_true = 1

  ctypedef enum CassError:
    CASS_OK = 0
    CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS = 16777227
    CASS_ERROR_SERVER_SYNTAX_ERROR = 33562624
    CASS_ERROR_SERVER_INVALID_QUERY = 33563136
    

  ctypedef enum CassProtocolVersion:
    CASS_PROTOCOL_VERSION_V1 = 1
    CASS_PROTOCOL_VERSION_V2 = 2
    CASS_PROTOCOL_VERSION_V3 = 3
    CASS_PROTOCOL_VERSION_V4 = 4
    CASS_PROTOCOL_VERSION_V5 = 5

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

  ctypedef void (*CassFutureCallback)(CassFuture* future, void* data);  

  CassCluster* cass_cluster_new()
  void cass_cluster_free(CassCluster* cluster)
  CassError cass_cluster_set_contact_points_n(CassCluster* cluster, const char* contact_points, size_t contat_points_length)
  CassError cass_cluster_set_protocol_version(CassCluster* cluster, int protocol_version)


  CassSession* cass_session_new()
  void cass_session_free(CassSession* session)
  CassFuture* cass_session_connect(CassSession* session, const CassCluster* cluster)
  CassFuture* cass_session_connect_keyspace_n(CassSession* session,const CassCluster* cluster, const char* keyspace, size_t keyspace_length)
  CassFuture* cass_session_execute(CassSession * session, const CassStatement* statement)
  CassFuture* cass_session_prepare_n(CassSession* session, const char* query, size_t query_length);
  CassFuture* cass_session_close(CassSession* session)

  CassStatement* cass_statement_new_n(const char* query, size_t query_length, size_t parameter_count)
  CassError cass_statement_bind_null(CassStatement* statement, size_t index)
  CassError cass_statement_bind_int32(CassStatement* statement, size_t index, cass_int32_t value)
  CassError cass_statement_bind_float(CassStatement* statement, size_t index, cass_float_t value)
  CassError cass_statement_bind_bool(CassStatement* statement, size_t index, cass_bool_t value)
  CassError cass_statement_bind_string_n(CassStatement* statement, size_t index, const char* value, size_t value_length)
  CassError cass_statement_bind_bytes(CassStatement* statement, size_t index, const cass_byte_t* value, size_t value_length)
  void cass_statement_free(CassStatement* statement)

  void cass_future_free(CassFuture* future)
  CassError cass_future_error_code(CassFuture* future);
  CassError cass_future_set_callback(CassFuture* future, CassFutureCallback callback, void* data)
  CassErrorResult* cass_future_get_error_result(CassFuture* future)
  CassResult* cass_future_get_result(CassFuture* future)
  const CassPrepared* cass_future_get_prepared(CassFuture* future);
 
  CassError cass_error_result_code(CassErrorResult* error_result)
  void cass_error_result_free(CassErrorResult* error_result)

  size_t cass_result_row_count(CassResult* result)
  size_t cass_result_column_count(CassResult* result)
  CassRow* cass_result_first_row(CassResult* result)
  CassIterator* cass_iterator_from_result(const CassResult* result)
  void cass_result_free(CassResult* result)

  const CassValue* cass_row_get_column_by_name(const CassRow* row, const char* name)

  CassError cass_value_get_int32(const CassValue* value, cass_int32_t * output)

  CassRow* cass_iterator_get_row(const CassIterator* iterator)
  cass_bool_t cass_iterator_next(CassIterator* iterator)
  void cass_iterator_free(CassIterator* iterator)

  CassStatement* cass_prepared_bind(const CassPrepared* prepared);
  void cass_prepared_free(const CassPrepared* prepared);
