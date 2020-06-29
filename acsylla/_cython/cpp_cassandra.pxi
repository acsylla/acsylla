ctypedef unsigned int       uint32_t

cdef extern from "cassandra.h":
  ctypedef enum CassError:
    CASS_OK

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

  ctypedef struct CassStatement:
    pass

  ctypedef struct CassErrorResult:
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
  CassFuture* cass_session_close(CassSession* session)

  CassStatement* cass_statement_new_n(const char* query, size_t query_length, size_t parameter_count)
  void cass_statement_free(CassStatement* statement)

  void cass_future_free(CassFuture* future)
  CassError cass_future_set_callback(CassFuture* future, CassFutureCallback callback, void* data)
  CassErrorResult* cass_future_get_error_result(CassFuture* future)
  
  CassError cass_error_result_code(CassErrorResult* error_result)
  void cass_error_result_free(CassErrorResult* error_result)
