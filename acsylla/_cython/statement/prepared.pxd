cdef class PreparedStatement:
    cdef:
        CassStatement* cass_statement
