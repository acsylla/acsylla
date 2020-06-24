ctypedef unsigned int       uint32_t

cdef extern from "cassandra.h":
  ctypedef enum CassError:
    CASS_OK

  ctypedef struct CassCluster:
    pass

  ctypedef struct CassSession:
    pass

  ctypedef struct CassFuture:
    pass

  ctypedef void (*CassFutureCallback)(CassFuture* future, void* data);  

  CassCluster* cass_cluster_new()
  void cass_cluster_free(CassCluster* cluster)
  CassError cass_cluster_set_contact_points(CassCluster* cluster, const char* contact_points)

  CassSession* cass_session_new()
  void cass_session_free(CassSession* session)
  CassFuture* cass_session_connect(CassSession* session, const CassCluster* cluster)

  void cass_future_free(CassFuture* future)
  CassError cass_future_set_callback(CassFuture* future, CassFutureCallback callback, void* data)
