cdef class Metadata:
    cdef:
        CassSession* cass_session
        const CassSchemaMeta* cass_schema_meta
        const CassSchemaMeta* _get_schema_meta(self)
        const CassKeyspaceMeta* _get_keyspace_meta(self, object keyspace) except *
        const CassTableMeta* _get_table_meta(self, object keyspace, object table)  except *
    @staticmethod
    cdef Metadata new_(CassSession* cass_session)

cdef object _fields_from_keyspace_meta(const CassKeyspaceMeta* keyspace_meta)
cdef object _keyspace_meta(const CassKeyspaceMeta* keyspace_meta)
cdef object _fields_from_table_meta(const CassTableMeta* table_meta)
cdef object _tables_meta(const CassKeyspaceMeta* keyspace_meta)
cdef object _fields_from_column_meta(const CassColumnMeta* column_meta)
cdef object _columns_meta(const CassTableMeta* table_meta)
cdef object _fields_from_index_meta(const CassIndexMeta* index_meta)
cdef object _indexes_meta_from_table_meta(const CassTableMeta* table_meta, object keyspace_name)
cdef object _materialized_views_meta(const CassKeyspaceMeta* keyspace_meta)
cdef object _materialized_views_from_table_meta(const CassTableMeta* table_meta)
cdef object _fields_from_materialized_view_meta(const CassMaterializedViewMeta* materialized_view_meta)
cdef object _columns_from_materialized_view_meta(const CassMaterializedViewMeta* materialized_view_meta)
cdef object _get_nested_types(const CassDataType* data_type)
cdef object _user_types_meta(const CassKeyspaceMeta* keyspace_meta)
cdef object _fields_from_function_meta(const CassFunctionMeta* function_meta)
cdef object _functions_meta(const CassKeyspaceMeta* keyspace_meta)
