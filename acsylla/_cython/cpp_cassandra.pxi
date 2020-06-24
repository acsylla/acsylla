ctypedef unsigned int       uint32_t

cdef extern from "cassandra.h":
  ctypedef enum CassError:
    CASS_OK

  ctypedef struct CassCluster:
    pass

  CassCluster* cass_cluster_new()
  CassError cass_cluster_set_contact_points(CassCluster* cluster, const char* contact_points)
