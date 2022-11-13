
column_type_map = {
    CASS_COLUMN_TYPE_REGULAR: 'regular',
    CASS_COLUMN_TYPE_PARTITION_KEY: 'partition_key',
    CASS_COLUMN_TYPE_CLUSTERING_KEY: 'clustering_key',
    CASS_COLUMN_TYPE_STATIC: 'static',
    CASS_COLUMN_TYPE_COMPACT_VALUE: 'compact_value'
}

column_data_type_map = {
    CASS_VALUE_TYPE_UNKNOWN: 'unknown',
    CASS_VALUE_TYPE_CUSTOM: 'custom',
    CASS_VALUE_TYPE_ASCII: 'ascii',
    CASS_VALUE_TYPE_BIGINT: 'bigint',
    CASS_VALUE_TYPE_BLOB: 'blob',
    CASS_VALUE_TYPE_BOOLEAN: 'boolean',
    CASS_VALUE_TYPE_COUNTER: 'counter',
    CASS_VALUE_TYPE_DECIMAL: 'decimal',
    CASS_VALUE_TYPE_DOUBLE: 'double',
    CASS_VALUE_TYPE_FLOAT: 'float',
    CASS_VALUE_TYPE_INT: 'int',
    CASS_VALUE_TYPE_TEXT: 'text',
    CASS_VALUE_TYPE_TIMESTAMP: 'timestamp',
    CASS_VALUE_TYPE_UUID: 'uuid',
    CASS_VALUE_TYPE_VARCHAR: 'varchar',
    CASS_VALUE_TYPE_VARINT: 'varint',
    CASS_VALUE_TYPE_TIMEUUID: 'timeuuid',
    CASS_VALUE_TYPE_INET: 'inet',
    CASS_VALUE_TYPE_DATE: 'date',
    CASS_VALUE_TYPE_TIME: 'time',
    CASS_VALUE_TYPE_SMALL_INT: 'smallint',
    CASS_VALUE_TYPE_TINY_INT: 'tinyint',
    CASS_VALUE_TYPE_DURATION: 'duration',
    CASS_VALUE_TYPE_LIST: 'list',
    CASS_VALUE_TYPE_MAP: 'map',
    CASS_VALUE_TYPE_SET: 'set',
    CASS_VALUE_TYPE_UDT: 'udt',
    CASS_VALUE_TYPE_TUPLE: 'tuple',
}

index_type_map = {
    CASS_INDEX_TYPE_UNKNOWN: 'unknown',
    CASS_INDEX_TYPE_KEYS: 'keys',
    CASS_INDEX_TYPE_CUSTOM: 'custom',
    CASS_INDEX_TYPE_COMPOSITES: 'composites',
}


cdef object _fields_from_keyspace_meta(const CassKeyspaceMeta* keyspace_meta):
    cdef CassIterator* cass_iterator
    cdef size_t length = 0
    cdef const char* field_name
    cdef const CassValue* field_value

    fields = {}
    try:
        cass_iterator = cass_iterator_fields_from_keyspace_meta(keyspace_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            cass_iterator_get_meta_field_name(cass_iterator, <const char **> &field_name, <size_t*>&length)
            field_value = cass_iterator_get_meta_field_value(cass_iterator)
            fields[field_name[:length].decode()] = get_cass_value(field_value)
    finally:
        cass_iterator_free(cass_iterator)

    return fields


cdef object _keyspace_meta(const CassKeyspaceMeta* keyspace_meta):
    cdef CassIterator* cass_iterator

    cdef size_t length = 0
    cdef char* keyspace_name = NULL

    cass_keyspace_meta_name(keyspace_meta, <const char**> &keyspace_name, <size_t *>&length)

    from acsylla import KeyspaceMeta
    fields = _fields_from_keyspace_meta(keyspace_meta)
    keyspace = KeyspaceMeta(
        name=keyspace_name.decode(),
        is_virtual=True if cass_keyspace_meta_is_virtual(keyspace_meta) else False,
        user_types=_user_types_meta(keyspace_meta),
        functions=_functions_meta(keyspace_meta),
        aggregates=_aggregates_meta(keyspace_meta),
        tables=_tables_meta(keyspace_meta),
        **fields
    )

    return keyspace


cdef object _fields_from_table_meta(const CassTableMeta* table_meta):
    cdef CassIterator* cass_iterator
    cdef size_t length = 0
    cdef const char* field_name
    cdef const CassValue* field_value

    fields = {}
    try:
        cass_iterator = cass_iterator_fields_from_table_meta(table_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            cass_iterator_get_meta_field_name(cass_iterator, <const char**>&field_name, <size_t*>&length)
            field_value = cass_iterator_get_meta_field_value(cass_iterator)
            fields[field_name[:length].decode()] = get_cass_value(field_value)
    finally:
        cass_iterator_free(cass_iterator)

    return fields


cdef object _tables_meta(const CassKeyspaceMeta* keyspace_meta):
    cdef CassIterator* cass_iterator
    cdef const CassTableMeta* table_meta

    from acsylla import TableMeta
    tables = []
    try:
        cass_iterator = cass_iterator_tables_from_keyspace_meta(keyspace_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            table_meta = cass_iterator_get_table_meta(cass_iterator)
            fields = _fields_from_table_meta(table_meta)
            is_virtual = True if cass_table_meta_is_virtual(table_meta) else False
            indexes = _indexes_meta_from_table_meta(table_meta, fields['keyspace_name'])
            exclude_indexes = [f'{i.name}_index' for i in indexes]
            materialized_views = [k for k in _materialized_views_from_table_meta(table_meta) if k.name not in exclude_indexes]
            tables.append(TableMeta(
                name=fields['table_name'],
                is_virtual=is_virtual,
                columns=_columns_meta(table_meta),
                indexes=indexes,
                materialized_views=materialized_views,
                **fields))
    finally:
        cass_iterator_free(cass_iterator)

    return tables


cdef object _fields_from_column_meta(const CassColumnMeta* column_meta):
    cdef CassIterator* cass_iterator
    cdef size_t length = 0
    cdef const char* field_name
    cdef const CassValue* field_value

    fields = {}
    try:
        cass_iterator = cass_iterator_fields_from_column_meta(column_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            cass_iterator_get_meta_field_name(cass_iterator, <const char**>&field_name, <size_t*>&length)
            field_value = cass_iterator_get_meta_field_value(cass_iterator)
            fields[field_name[:length].decode()] = get_cass_value(field_value)
    finally:
        cass_iterator_free(cass_iterator)

    return fields


cdef object _columns_meta(const CassTableMeta* table_meta):
    cdef CassIterator* cass_iterator
    cdef const CassColumnMeta* column_meta

    cdef size_t length = 0
    cdef char* column_name = NULL
    cdef CassColumnType column_type
    cdef const CassDataType* data_type
    cdef CassValueType value_type

    from acsylla import ColumnMeta
    columns = []
    try:
        cass_iterator = cass_iterator_columns_from_table_meta(table_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            column_meta = cass_iterator_get_column_meta(cass_iterator)
            cass_column_meta_name(column_meta, <const char**> &column_name, <size_t *> &length)
            data_type = cass_column_meta_data_type(column_meta)
            fields = _fields_from_column_meta(column_meta)
            columns.append(ColumnMeta(
                name=fields['column_name'],
                **fields
            ))
    finally:
        cass_iterator_free(cass_iterator)

    return columns


cdef object _materialized_views_from_table_meta(const CassTableMeta* table_meta):
    cdef CassIterator* cass_iterator
    cdef const CassMaterializedViewMeta* materialized_view_meta

    from acsylla import MaterializedViewMeta

    materialized_views = []
    try:
        cass_iterator = cass_iterator_materialized_views_from_table_meta(table_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            materialized_view_meta = cass_iterator_get_materialized_view_meta(cass_iterator)
            fields = _fields_from_materialized_view_meta(materialized_view_meta)
            columns = _columns_from_materialized_view_meta(materialized_view_meta)
            materialized_views.append(MaterializedViewMeta(
                keyspace=fields['keyspace_name'],
                name=fields['view_name'],
                columns=columns,
                **fields
            ))
    finally:
        cass_iterator_free(cass_iterator)

    return materialized_views


cdef object _fields_from_index_meta(const CassIndexMeta* index_meta):
    cdef CassIterator* cass_iterator
    cdef size_t length = 0
    cdef const char* field_name
    cdef const CassValue* field_value

    fields = {}
    try:
        cass_iterator = cass_iterator_fields_from_index_meta(index_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            cass_iterator_get_meta_field_name(cass_iterator, <const char**>&field_name, <size_t*>&length)
            field_value = cass_iterator_get_meta_field_value(cass_iterator)
            fields[field_name[:length].decode()] = get_cass_value(field_value)
    finally:
        cass_iterator_free(cass_iterator)

    return fields


cdef object _indexes_meta_from_table_meta(const CassTableMeta* table_meta, object keyspace_name):
    cdef CassIterator* cass_iterator
    cdef const CassIndexMeta* index_meta

    cdef size_t length = 0
    cdef size_t length_t = 0
    cdef char* name = NULL
    cdef size_t table_name_length = 0
    cdef char* table_name = NULL
    cdef char* target = NULL
    cdef CassIndexType index_type
    cdef const CassValue* options

    cdef CassValueType cass_type

    from acsylla import IndexMeta
    indexes = []
    try:
        cass_table_meta_name(table_meta, <const char**> &table_name, <size_t *> &table_name_length)
        cass_iterator = cass_iterator_indexes_from_table_meta(table_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            index_meta = cass_iterator_get_index_meta(cass_iterator)
            cass_index_meta_name(index_meta, <const char**> &name, <size_t *> &length)
            cass_index_meta_target(index_meta, <const char**> &target, <size_t *> &length_t)
            options = cass_index_meta_options(index_meta)
            indexes.append(
                IndexMeta(
                    keyspace=keyspace_name,
                    table=table_name[:table_name_length].decode(),
                    name=name[:length].decode(),
                    target=target[:length_t].decode(),
                    kind=index_type_map[cass_index_meta_type(index_meta)],
                    options=get_cass_value(options)
                )
            )
    finally:
        cass_iterator_free(cass_iterator)

    return indexes


cdef object _fields_from_materialized_view_meta(const CassMaterializedViewMeta* materialized_view_meta):
    cdef CassIterator* cass_iterator
    cdef size_t length = 0
    cdef const char* field_name
    cdef const CassValue* field_value

    fields = {}
    try:
        cass_iterator = cass_iterator_fields_from_materialized_view_meta(materialized_view_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            cass_iterator_get_meta_field_name(cass_iterator, <const char**>&field_name, <size_t*>&length)
            field_value = cass_iterator_get_meta_field_value(cass_iterator)
            fields[field_name[:length].decode()] = get_cass_value(field_value)
    finally:
        cass_iterator_free(cass_iterator)
    return fields


cdef object _columns_from_materialized_view_meta(const CassMaterializedViewMeta* materialized_view_meta):
    cdef CassIterator* cass_iterator
    cdef const CassColumnMeta* column_meta

    from acsylla import ColumnMeta
    columns = []
    try:
        cass_iterator = cass_iterator_columns_from_materialized_view_meta(materialized_view_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            column_meta = cass_iterator_get_column_meta(cass_iterator)
            fields = _fields_from_column_meta(column_meta)
            columns.append(ColumnMeta(
                name=fields['column_name'],
                **fields
            ))
    finally:
        cass_iterator_free(cass_iterator)

    return columns


cdef object _materialized_views_meta(const CassKeyspaceMeta* keyspace_meta):
    cdef CassIterator* cass_iterator
    cdef const CassMaterializedViewMeta* materialized_view_meta

    from acsylla import MaterializedViewMeta

    materialized_views = []
    try:
        cass_iterator = cass_iterator_materialized_views_from_keyspace_meta(keyspace_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            materialized_view_meta = cass_iterator_get_materialized_view_meta(cass_iterator)
            fields = _fields_from_materialized_view_meta(materialized_view_meta)
            columns = _columns_from_materialized_view_meta(materialized_view_meta)
            materialized_views.append(MaterializedViewMeta(
                keyspace=fields['keyspace_name'],
                name=fields['view_name'],
                columns=columns,
                **fields
            ))
    finally:
        cass_iterator_free(cass_iterator)

    return materialized_views


cdef object _get_nested_types(const CassDataType* data_type):
    cdef size_t count = 0
    cdef size_t length = 0
    cdef char* name = NULL

    from acsylla import NestedTypeMeta
    nested_types = []
    count = cass_data_type_sub_type_count(data_type)
    for i in range(count):
        sub_data_type = cass_data_type_sub_data_type(data_type, <size_t>i)
        type_str = column_data_type_map[cass_data_type_type(sub_data_type)]
        is_frozen = True if cass_data_type_is_frozen(sub_data_type) else False
        if type_str == 'udt':
            error = cass_data_type_type_name(sub_data_type, <const char**>&name, <size_t*>&length)
            raise_if_error(error)
            type_str = name[:length].decode()
        nested_types.append(NestedTypeMeta(type=type_str, is_frozen=is_frozen))
    return nested_types


cdef object _user_types_meta(const CassKeyspaceMeta* keyspace_meta):
    cdef CassIterator* cass_iterator
    cdef const CassDataType* data_type
    cdef const CassDataType* sub_data_type

    cdef size_t count = 0
    cdef size_t length = 0
    cdef char* name = NULL
    cdef size_t keyspace_length = 0
    cdef char* keyspace_name = NULL
    cdef size_t sub_length = 0
    cdef char* sub_name = NULL
    cdef size_t udt_length = 0
    cdef char* udt_name = NULL

    cdef CassError error

    from acsylla import UserTypeFieldMeta
    from acsylla import UserTypeMeta
    user_types = []
    try:
        cass_iterator = cass_iterator_user_types_from_keyspace_meta(keyspace_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            data_type = cass_iterator_get_user_type(cass_iterator)
            error = cass_data_type_type_name(data_type, <const char**>&name, <size_t*>&length)
            raise_if_error(error)
            error = cass_data_type_keyspace(data_type, <const char**>&keyspace_name, <size_t*>&keyspace_length)
            raise_if_error(error)
            is_frozen = True if cass_data_type_is_frozen(data_type) else False
            user_type = UserTypeMeta(name=name[:length].decode(), keyspace=keyspace_name[:keyspace_length].decode(), is_frozen=is_frozen, fields=[])
            count = cass_data_type_sub_type_count(data_type)
            for i in range(count):
                sub_data_type = cass_data_type_sub_data_type(data_type, <size_t>i)
                error = cass_data_type_sub_type_name(data_type, <size_t>i, <const char**>&sub_name,<size_t*>&sub_length)
                raise_if_error(error)
                is_frozen = True if cass_data_type_is_frozen(sub_data_type) else False
                type_str = column_data_type_map[cass_data_type_type(sub_data_type)]
                if type_str in ('udt',):
                    error = cass_data_type_type_name(sub_data_type, <const char**>&udt_name, <size_t*>&udt_length)
                    raise_if_error(error)
                    type_str = udt_name[:udt_length].decode()
                nested_types = None
                if type_str in ('list', 'map', 'set', 'tuple'):
                    nested_types = _get_nested_types(sub_data_type)

                user_type.fields.append(UserTypeFieldMeta(
                    name=sub_name[:sub_length].decode(),
                    type=type_str,
                    is_frozen=is_frozen,
                    nested_types=nested_types
                ))
            user_types.append(user_type)
    finally:
        cass_iterator_free(cass_iterator)

    return user_types


cdef object _fields_from_function_meta(const CassFunctionMeta* function_meta):
    cdef CassIterator* cass_iterator
    cdef size_t length = 0
    cdef const char* field_name
    cdef const CassValue* field_value

    fields = {}
    try:
        cass_iterator = cass_iterator_fields_from_function_meta(function_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            cass_iterator_get_meta_field_name(cass_iterator, <const char**>&field_name, <size_t*>&length)
            field_value = cass_iterator_get_meta_field_value(cass_iterator)
            fields[field_name[:length].decode()] = get_cass_value(field_value)
    finally:
        cass_iterator_free(cass_iterator)

    return fields


cdef object _functions_meta(const CassKeyspaceMeta* keyspace_meta):
    cdef CassIterator* cass_iterator
    cdef const CassFunctionMeta* function_meta

    from acsylla import FunctionMeta

    functions = []
    try:
        cass_iterator = cass_iterator_functions_from_keyspace_meta(keyspace_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            function_meta = cass_iterator_get_function_meta(cass_iterator)
            fields = _fields_from_function_meta(function_meta)
            functions.append(
                FunctionMeta(keyspace=fields['keyspace_name'],
                             name=fields['function_name'],
                             **fields))
    finally:
        cass_iterator_free(cass_iterator)

    return functions


cdef object _fields_from_aggregate_meta(const CassAggregateMeta* aggregate_meta):
    cdef CassIterator* cass_iterator
    cdef size_t length = 0
    cdef const char* field_name
    cdef const CassValue* field_value

    fields = {}
    try:
        cass_iterator = cass_iterator_fields_from_aggregate_meta(aggregate_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            cass_iterator_get_meta_field_name(cass_iterator, <const char**>&field_name, <size_t*>&length)
            field_value = cass_iterator_get_meta_field_value(cass_iterator)
            fields[field_name[:length].decode()] = get_cass_value(field_value)
    finally:
        cass_iterator_free(cass_iterator)

    return fields


cdef object _aggregates_meta(const CassKeyspaceMeta* keyspace_meta):
    cdef CassIterator* cass_iterator
    cdef const CassAggregateMeta* aggregate_meta

    from acsylla import AggregateMeta

    aggregates = []
    try:
        cass_iterator = cass_iterator_aggregates_from_keyspace_meta(keyspace_meta)
        while cass_iterator_next(cass_iterator) == cass_true:
            aggregate_meta = cass_iterator_get_aggregate_meta(cass_iterator)
            fields = _fields_from_aggregate_meta(aggregate_meta)
            aggregates.append(
                AggregateMeta(keyspace=fields['keyspace_name'],
                             name=fields['aggregate_name'],
                             **fields))
    finally:
        cass_iterator_free(cass_iterator)

    return aggregates


cdef class Metadata:

    @staticmethod
    cdef Metadata new_(CassSession* cass_session):
        metadata = Metadata()
        metadata.cass_session = cass_session
        return metadata

    def __dealloc__(self):
        if self.cass_schema_meta:
            cass_schema_meta_free(self.cass_schema_meta)

    cdef const CassSchemaMeta* _get_schema_meta(self) except *:
        if self.cass_schema_meta:
            cass_schema_meta_free(self.cass_schema_meta)
        self.cass_schema_meta = cass_session_get_schema_meta(self.cass_session)
        if self.cass_schema_meta == NULL:
            raise SchemaNotAvailable("Could not retrieve schema metadata from cluster!")
        return self.cass_schema_meta

    cdef const CassKeyspaceMeta* _get_keyspace_meta(self, object keyspace) except *:
        cdef const CassKeyspaceMeta* keyspace_meta
        keyspace_meta = cass_schema_meta_keyspace_by_name(self._get_schema_meta(), keyspace.encode())
        if keyspace_meta == NULL:
            raise KeyspaceNotFound(f'Keyspace "{keyspace}" not found')
        return keyspace_meta

    cdef const CassTableMeta* _get_table_meta(self, object keyspace, object table) except *:
        cdef const CassTableMeta* table_meta
        table_meta = cass_keyspace_meta_table_by_name(self._get_keyspace_meta(keyspace), table.encode())
        if table_meta == NULL:
            raise TableNotFound(f'Table "{table}" not found')
        return table_meta

    def get_version(self):
        cdef CassVersion v = cass_schema_meta_version(self._get_schema_meta())
        return v.major_version, v.minor_version, v.patch_version

    def get_snapshot_version(self):
        return cass_schema_meta_snapshot_version(self._get_schema_meta())

    def get_keyspaces(self):
        cdef CassIterator* cass_iterator
        cdef size_t length = 0
        cdef char* keyspace_name = NULL
        keyspaces = []
        schema_meta = self._get_schema_meta()
        if not schema_meta:
            return keyspaces
        try:
            cass_iterator = cass_iterator_keyspaces_from_schema_meta(schema_meta)
            while cass_iterator_next(cass_iterator) == cass_true:
                keyspace_meta = cass_iterator_get_keyspace_meta(cass_iterator)
                cass_keyspace_meta_name(keyspace_meta, <const char**> &keyspace_name, <size_t*> &length)
                keyspaces.append(keyspace_name[:length].decode())
        finally:
            cass_iterator_free(cass_iterator)

        return keyspaces

    def get_keyspace_meta(self, keyspace):
        return _keyspace_meta(self._get_keyspace_meta(keyspace))

    def get_user_types(self, keyspace):
        return [k.name for k in _user_types_meta(self._get_keyspace_meta(keyspace))]

    def get_user_types_meta(self, keyspace):
        return _user_types_meta(self._get_keyspace_meta(keyspace))

    def get_user_type_meta(self, keyspace, name):
        try:
            return [k for k in _user_types_meta(self._get_keyspace_meta(keyspace)) if k.name==name][0]
        except IndexError:
            raise UserTypeNotFound(f'User type "{name}" not found')

    def get_functions(self, keyspace):
        return [k.name for k in _functions_meta(self._get_keyspace_meta(keyspace))]

    def get_functions_meta(self, keyspace):
        return _functions_meta(self._get_keyspace_meta(keyspace))

    def get_function_meta(self, keyspace, name):
        try:
            return [k for k in _functions_meta(self._get_keyspace_meta(keyspace)) if k.name==name][0]
        except IndexError:
            raise FunctionNotFound(f'Function "{name}" not found')

    def get_aggregates(self, keyspace):
        return [k.name for k in _aggregates_meta(self._get_keyspace_meta(keyspace))]

    def get_aggregates_meta(self, keyspace):
        return _aggregates_meta(self._get_keyspace_meta(keyspace))

    def get_aggregate_meta(self, keyspace, name):
        try:
            return [k for k in _aggregates_meta(self._get_keyspace_meta(keyspace)) if k.name==name][0]
        except IndexError:
            raise AggregateNotFound(f'Aggregate "{name}" not found')

    def get_tables(self, keyspace):
        return [k.name for k in _tables_meta(self._get_keyspace_meta(keyspace))]

    def get_tables_meta(self, keyspace):
        return _tables_meta(self._get_keyspace_meta(keyspace))

    def get_table_meta(self, keyspace, name):
        try:
            return [k for k in _tables_meta(self._get_keyspace_meta(keyspace)) if k.name==name][0]
        except IndexError:
            raise TableNotFound(f'Table "{name}" not found')

    def get_indexes(self, keyspace):
        return [k.name for k in self.get_indexes_meta(keyspace)]

    def get_indexes_meta(self, keyspace):
        return [k for k in sum([k.indexes for k in _tables_meta(self._get_keyspace_meta(keyspace))], [])]

    def get_index_meta(self, keyspace, name):
        try:
            return [k for k in self.get_indexes_meta(keyspace) if k.name==name][0]
        except IndexError:
            raise IndexNotFound(f'Index "{name}" not found')

    def get_materialized_views(self, keyspace):
        return [k.name for k in _materialized_views_meta(self._get_keyspace_meta(keyspace))]

    def get_materialized_views_meta(self, keyspace):
        return _materialized_views_meta(self._get_keyspace_meta(keyspace))

    def get_materialized_view_meta(self, keyspace, name):
        try:
            return [k for k in _materialized_views_meta(self._get_keyspace_meta(keyspace)) if k.name==name][0]
        except IndexError:
            raise MaterializedViewNotFound(f'Materialized view "{name}" not found')
