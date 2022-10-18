"""Abstract base classes, use them for documentation or for adding
types in your functions."""
from abc import ABCMeta
from abc import abstractmethod
from acsylla._cython import cyacsylla
from dataclasses import dataclass
from datetime import date
from datetime import datetime
from datetime import time
from datetime import timedelta
from decimal import Decimal
from enum import Enum
from ipaddress import IPv4Address
from ipaddress import IPv6Address
from typing import Dict
from typing import Iterable
from typing import List
from typing import Mapping
from typing import Optional
from typing import Sequence
from typing import Set
from typing import Union
from uuid import UUID

import json

SupportedType = Union[
    None,
    int,
    float,
    bool,
    str,
    bytes,
    list,
    set,
    dict,
    tuple,
    UUID,
    datetime,
    date,
    time,
    timedelta,
    IPv4Address,
    IPv6Address,
    Decimal,
]


class Cluster(metaclass=ABCMeta):
    """Provides a Cluster instance class. Use the factory `create_cluster`
    for creating a new instance"""

    @abstractmethod
    async def create_session(self, keyspace: Optional[str] = None) -> "Session":
        """Returns a new session by using the Cluster configuration.

        If Keyspace is provided, the session will be bound to the keyspace and
        any statment, unlesss says the opposite, will be using that keyspace.

        The coroutine will try to make a connection to the cluster hosts.
        """


class Meta(metaclass=ABCMeta):
    """Provides a Meta instance class for retrieving metadata from cluster."""

    @abstractmethod
    def version(self) -> tuple:
        """Gets the version of the connected cluster."""

    @abstractmethod
    def snapshot_version(self) -> int:
        """Gets the version of the schema metadata snapshot."""

    @abstractmethod
    def keyspaces_names(self) -> List[str]:
        """Returns a list of all keyspaces names from cluster."""

    @abstractmethod
    def keyspace(self, name) -> "KeyspaceMeta":
        """Returns metadata for given keyspace."""

    @abstractmethod
    def user_types_names(self, keyspace) -> List[str]:
        """Returns a list of user defined types (UDT) names for given keyspace name."""

    @abstractmethod
    def user_types(self, keyspace) -> List["UserTypeMeta"]:
        """Returns a list of user defined types (UDT) metadata for given keyspace name."""

    @abstractmethod
    def user_type(self, keyspace, name) -> "UserTypeMeta":
        """Returns metadata for user defined types (UDT) for given keyspace name and type name."""

    @abstractmethod
    def functions_names(self, keyspace) -> List[str]:
        """Returns a list of functions names for the given keyspace name."""

    @abstractmethod
    def functions(self, keyspace) -> List["FunctionMeta"]:
        """Returns a list of functions metadata for given keyspace name."""

    @abstractmethod
    def function(self, keyspace, name) -> "FunctionMeta":
        """Returns metadata for function for given keyspace name and function name."""

    @abstractmethod
    def tables_names(self, keyspace) -> List[str]:
        """Returns a list of tables names for the given keyspace name."""

    @abstractmethod
    def tables(self, keyspace) -> List["TableMeta"]:
        """Returns a list of tables metadata for given keyspace name."""

    @abstractmethod
    def table(self, keyspace, name) -> "TableMeta":
        """Returns metadata for table for given keyspace name and table name."""

    @abstractmethod
    def indexes_names(self, keyspace) -> List[str]:
        """Returns a list of indexes names for the given keyspace name."""

    @abstractmethod
    def indexes(self, keyspace) -> List["IndexMeta"]:
        """Returns a list of indexes metadata for given keyspace name."""

    @abstractmethod
    def index(self, keyspace, name) -> "IndexMeta":
        """Returns metadata for index for given keyspace name and index name."""

    @abstractmethod
    def materialized_views_names(self, keyspace) -> List[str]:
        """Returns a list of materialized views names for the given keyspace name."""

    @abstractmethod
    def materialized_views(self, keyspace) -> List["MaterializedViewMeta"]:
        """Returns a list of materialized views metadata for given keyspace name."""

    @abstractmethod
    def materialized_view(self, keyspace, name) -> "MaterializedViewMeta":
        """Returns metadata for materialized view for given keyspace name and materialized view name."""


class Session(metaclass=ABCMeta):
    """Provides a Session instance class. Use the the
    `Cluster.create_session` coroutine for creating a new instance"""

    meta: Meta

    @abstractmethod
    async def close(self):
        """Closes a session.

        After calling this method no more executions will be allowed
        raising the proper excetion if this is the case.
        """

    @abstractmethod
    async def execute(self, statement: "Statement") -> "Result":
        """Executes an statement and returns the result."""

    @abstractmethod
    async def create_prepared(self, statement: str, timeout: Optional[float] = None) -> "PreparedStatement":
        """Prepares an statement.

        By providing a `timeout` all requests built by the prepared statement will use it,
        otherwise timeout provided during the Cluster instantantation will be used. Value expected is seconds.
        """

    @abstractmethod
    async def execute_batch(self, batch: "Batch") -> None:
        """Executes a batch of statements."""

    @abstractmethod
    async def metrics(self) -> "SessionMetrics":
        """Returns the metrics related to the session."""


class Statement(metaclass=ABCMeta):
    """Provides a Statement instance class. Use the the
    `create_statement` factory for creating a new instance"""

    @abstractmethod
    def bind(self, index: int, value: SupportedType) -> None:
        """Binds the value to a specific index parameter.

        Types support for now: None, bool, int, float, str, bytes, and UUID.

        If an invalid type is used for a prepared statement this will raise
        immediately an error. If a none prepared exception is used error will
        be raised later during the execution statement.

        If an invalid index is used this will raise immediately an error
        """

    @abstractmethod
    def bind_by_name(self, name: str, value: SupportedType) -> None:
        """Binds the the value to a specific parameter by name.

        Types support for now: None, bool, int, float, str, bytes, and UUID.

        If an invalid type is used for this will raise immediately an error. If an
        invalid name is used this will raise immediately an error
        """

    @abstractmethod
    def bind_list(self, values: Sequence[SupportedType]) -> None:
        """Binds the values into all parameters from left to right.

        For types supported and errors that this function might raise take
        a look at the `Statement.bind` function.
        """

    # following methods are only allowed for statements
    # created using prepared statements

    @abstractmethod
    def bind_dict(self, values: Mapping[str, SupportedType]) -> None:
        """Binds the values into all parameter names. Names are the keys
        of the mapping provided.

        For types supported and errors that this function might raise take
        a look at the `Statement.bind_dict` function.
        """

    @abstractmethod
    def set_page_size(self, page_size: int) -> None:
        """Sets the statement's page size."""

    @abstractmethod
    def set_page_state(self, page_state: bytes) -> None:
        """Sets the statement's paging state. This can be used to get the next
        page of data in a multi-page query.

        Warning: The paging state should not be exposed to or come from
        untrusted environments. The paging state could be spoofed and potentially
        used to gain access to other data.
        """

    @abstractmethod
    def set_timeout(self, timeout: float) -> None:
        """Sets the statement's timeout in seconds for waiting for a response from a node.
        Default: Disabled (use the cluster-level request timeout)"""

    @abstractmethod
    def set_consistency(self, timeout: float) -> None:
        """Sets the statement’s consistency level.
        Default: LOCAL_ONE"""

    @abstractmethod
    def set_serial_consistency(self, timeout: float) -> None:
        """Sets the statement’s serial consistency level.
        Default: Not set"""


class PreparedStatement(metaclass=ABCMeta):
    """Provides a PreparedStatement instance class. Use the
    `session.create_prepared()` coroutine for creating a new instance"""

    @abstractmethod
    def bind(self, page_size: Optional[int] = None, page_state: Optional[bytes] = None) -> Statement:
        """Returns a new statment using the prepared."""


class Batch(metaclass=ABCMeta):
    """Provides a Batch instance class. Use the
    `create_batch_logged()` and `create_batch_unlogged` factories
    for creating a new instance."""

    @abstractmethod
    def add_statement(self, statement: Statement) -> None:
        """Adds a new statement to the batch."""


class Result(metaclass=ABCMeta):
    """Provides a result instance class. Use the
    `session.execute()` coroutine for getting the result
    from a query"""

    @abstractmethod
    def count(self) -> int:
        """Returns the total rows of the result"""

    @abstractmethod
    def column_count(self) -> int:
        """Returns the total columns returned"""

    @abstractmethod
    def first(self) -> Optional["Row"]:
        """Return the first result, if there is no row
        returns None.
        """

    @abstractmethod
    def all(self) -> Iterable["Row"]:
        """Return the all rows using of a result, using an
        iterator.

        If there is no rows iterator returns no rows.
        """

    @abstractmethod
    def has_more_pages(self) -> bool:
        """Returns true if there is still pages to be fetched"""

    @abstractmethod
    def page_state(self) -> bytes:
        """Returns a token with the page state for continuing fetching
        new results.

        Before calling this method you must first checks if there are more
        results using the `has_more_pages` function, and if there are use the
        token returned by this function as an argument of the factories for creating
        an statement for returning the next page.
        """


class Row(metaclass=ABCMeta):
    """Provides access to a row of a `Result`"""

    @abstractmethod
    def as_dict(self) -> dict:
        """Returns the row as dict."""

    @abstractmethod
    def as_list(self) -> list:
        """Returns the row as list."""

    @abstractmethod
    def as_tuple(self) -> tuple:
        """Returns the row as tuple."""

    @abstractmethod
    def as_named_tuple(self) -> tuple:
        """Returns the row as named tuple."""

    @abstractmethod
    def column_count(self) -> int:
        """Returns column count."""

    @abstractmethod
    def column_value(self, name: str) -> SupportedType:
        """Returns the row column value called by `name`.

        Raises a `CassException` derived exception if the column can not be found

        Type is inferred by using the Cassandra driver
        and converted, if supported, to a Python type or one
        of the extended types provided by Acsylla.

        Types support for now: None, bool, int, float, str, bytes, and UUID.
        """

    @abstractmethod
    def column_value_by_index(self, index):
        """Returns the column value by `column index`.
        Raises an exception if the column can not be found"""


@dataclass
class SessionMetrics:
    """Provides basic metrics for the Session."""

    # requests time statistics in microseconds.
    requests_min: int
    requests_max: int
    requests_mean: int
    requests_stddev: int
    requests_median: int
    requests_percentile_75th: int
    requests_percentile_95th: int
    requests_percentile_98th: int
    requests_percentile_99th: int
    requests_percentile_999th: int

    # requests rate, requests per second
    requests_mean_rate: float
    requests_one_minute_rate: float
    requests_five_minute_rate: float
    requests_fifteen_minute_rate: float

    # Total connections available
    stats_total_connections: int

    # counters of timeouts at connection and
    # request level
    errors_connection_timeouts: int
    errors_request_timeouts: int


class Consistency(Enum):
    ANY = cyacsylla.Consistency.ANY
    ONE = cyacsylla.Consistency.ONE
    TWO = cyacsylla.Consistency.TWO
    THREE = cyacsylla.Consistency.THREE
    QUORUM = cyacsylla.Consistency.QUORUM
    ALL = cyacsylla.Consistency.ALL
    LOCAL_QUORUM = cyacsylla.Consistency.LOCAL_QUORUM
    EACH_QUORUM = cyacsylla.Consistency.EACH_QUORUM
    SERIAL = cyacsylla.Consistency.SERIAL
    LOCAL_SERIAL = cyacsylla.Consistency.LOCAL_SERIAL
    LOCAL_ONE = cyacsylla.Consistency.LOCAL_ONE


class SSLVerifyFlags(Enum):
    """
    Sets verification performed on the peer’s certificate.

    NONE - No verification is performed
    PEER_CERT - Certificate is present and valid
    PEER_IDENTITY - IP address matches the certificate’s common name or one of its
      subject alternative names. This implies the certificate is also present.
    PEER_IDENTITY_DNS - Hostname matches the certificate’s common name or
      one of its subject alternative names. This implies the certificate is
      also present. Hostname resolution must also be enabled.
    """

    NONE = cyacsylla.SSLVerifyFlags.NONE
    PEER_CERT = cyacsylla.SSLVerifyFlags.PEER_CERT
    PEER_IDENTITY = cyacsylla.SSLVerifyFlags.PEER_IDENTITY
    PEER_IDENTITY_DNS = cyacsylla.SSLVerifyFlags.PEER_IDENTITY_DNS


@dataclass
class LogMessage:
    """Log message"""

    time_ms: int
    log_level: str
    file: str
    line: int
    function: str
    message: str


@dataclass
class NestedTypeMeta:
    """User type field metadata."""

    type: str
    is_frozen: bool


@dataclass
class UserTypeFieldMeta:
    """User type field metadata."""

    name: str
    type: str
    is_frozen: bool
    nested_types: List[NestedTypeMeta]


@dataclass
class UserTypeMeta:
    """User type metadata."""

    keyspace: str
    name: str
    is_frozen: bool
    fields: List[UserTypeFieldMeta]

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate this type.
        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        user type name in CREATE statement.
        For example CREATE TYPE keyspace_name.type_name... if with_keyspace is
        set to False, statement will be CREATE TYPE type_name.."""

        keyspace = f"{self.keyspace}."
        if with_keyspace is False:
            keyspace = ""
        query = f"CREATE TYPE {keyspace}{self.name} ("
        for field in self.fields:
            nested = ""
            if field.nested_types:
                nested = []
                for el in field.nested_types:
                    if el.is_frozen:
                        nested.append(f"frozen<{el.type}>")
                    else:
                        nested.append(f"{el.type}")
                nested = ", ".join(nested)

            if field.is_frozen:
                if field.nested_types:
                    query += f"\n\t{field.name} frozen<{field.type}<{nested}>>,"
                else:
                    query += f"\n\t{field.name} frozen<{field.type}>,"
            else:
                if field.nested_types:
                    query += f"\n\t{field.name} {field.type}<{nested}>,"
                else:
                    query += f"\n\t{field.name} {field.type},"
        query = query[:-1]
        query += "\n);"

        if formatted is False:
            query = query.replace("\n\t", " ").replace("( ", "(").replace("\n);", ");")
        return [query]


@dataclass
class FunctionMeta:
    """Function metadata."""

    keyspace: str
    name: str
    function_name: str
    keyspace_name: str
    argument_names: List[str]
    argument_types: List[str]
    called_on_null_input: bool
    language: str
    body: str
    return_type: str

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate function.
        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        function name in CREATE statement.
        For example CREATE FUNCTION keyspace_name.function_name... if with_keyspace
        is set to False, statement will be CREATE FUNCTION function_name..."""

        keyspace = f"{self.keyspace}."
        if with_keyspace is False:
            keyspace = ""
        args = ", ".join([" ".join(k) for k in zip(self.argument_names, self.argument_types)])
        query = f"CREATE FUNCTION {keyspace}{self.name}({args})\n\t"
        if self.called_on_null_input:
            query += "CALLED ON NULL INPUT\n\t"
        else:
            query += "RETURNS NULL ON NULL INPUT\n\t"
        query += f"RETURNS {self.return_type}\n\t"
        query += f"LANGUAGE {self.language}\n\tAS $${self.body}$$;"

        if formatted is False:
            query = query.replace("\n\t", " ")
        return [query]


@dataclass
class AggregateMeta:
    """Aggregate metadata."""

    keyspace: str
    keyspace_name: str
    name: str
    aggregate_name: str
    argument_types: List[str]
    initcond: str
    state_func: str
    state_type: str
    final_func: str
    return_type: str

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate aggregate.
        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        function name in CREATE statement.
        For example CREATE AGGREGATE keyspace_name.aggregate_name... if with_keyspace
        is set to False, statement will be CREATE AGGREGATE aggregate_name..."""

        keyspace = f"{self.keyspace}."
        if with_keyspace is False:
            keyspace = ""
        args = ", ".join(self.argument_types)
        query = f"CREATE AGGREGATE {keyspace}{self.name}({args})\n\t"
        query += f"SFUNC {self.state_func}\n\t"
        query += f"STYPE {self.state_type}\n\t"
        query += f"FINALFUNC {self.final_func}\n\t"
        query += f"INITCOND {self.initcond};"

        if formatted is False:
            query = query.replace("\n\t", " ")
        return [query]


@dataclass
class ColumnMeta:
    """Column metadata."""

    name: str
    type: str
    clustering_order: str
    column_name: str
    column_name_bytes: bytes
    keyspace_name: str
    kind: str
    position: int
    table_name: str


@dataclass
class IndexMeta:
    """Index metadata."""

    keyspace: str
    table: str
    name: str
    kind: str
    target: str
    options: Dict[str, str]

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate this index.

        If with_keyspace is set to True, keyspace name will be added before
        index name in CREATE statement.
        For example CREATE INDEX keyspace_name.index_name...
        if with_keyspace is set to False, statement will be
        CREATE INDEX index_name...
        """

        keyspace = f"{self.keyspace}."
        if with_keyspace is False:
            keyspace = ""
        target = self.target
        if target.startswith('{"pk":["'):
            target = json.loads(target)
            pk = ",".join([k for k in target["pk"]])
            ck = ",".join([k for k in target["ck"]])
            target = f"(({pk}), {ck})"
        query = f"CREATE INDEX {self.name} ON {keyspace}{self.table} ({target});"

        if formatted is False:
            query = query.replace("\n\t", " ")
        return [query]


@dataclass
class MaterializedViewMeta:
    """Materialized view metadata."""

    keyspace: str
    name: str
    id: UUID
    base_table_id: UUID
    base_table_name: str
    bloom_filter_fp_chance: float
    caching: Dict[str, str]
    comment: str
    compaction: Dict[str, str]
    compression: Dict[str, str]
    crc_check_chance: float
    dclocal_read_repair_chance: float
    default_time_to_live: int
    extensions: Dict[str, str]
    gc_grace_seconds: int
    include_all_columns: bool
    keyspace_name: str
    max_index_interval: int
    memtable_flush_period_in_ms: int
    min_index_interval: 128
    read_repair_chance: int
    speculative_retry: str
    view_name: str
    where_clause: str
    columns: []

    def as_cql_query(self, formatted=False, with_keyspace=True) -> List[str]:
        """Returns a CQL query that can be used to recreate this
        materialized view.

        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        materialized view name in CREATE statement.
        For example CREATE MATERIALIZED VIEW keyspace_name.view_name...
        if with_keyspace is set to False, statement will be
        CREATE MATERIALIZED VIEW view_name..."""

        keyspace = f"{self.keyspace_name}."
        if with_keyspace is False:
            keyspace = ""
        query = f"CREATE MATERIALIZED VIEW {keyspace}{self.name} AS\n\t"
        if self.include_all_columns is True:
            query += "SELECT *\n\t"
        else:
            columns = ", ".join([k.column_name for k in self.columns])
            query += f"SELECT {columns}\n\t"
        query += f"FROM {keyspace}{self.base_table_name}\n\t"
        query += f"WHERE {self.where_clause}\n\t"
        pk = ", ".join([k.column_name for k in self.columns if k.kind in ("partition_key", "clustering")])
        query += f"PRIMARY KEY ({pk})\n\t"
        order = ", ".join(
            [
                f"{k.column_name} {k.clustering_order.upper()}"
                for k in self.columns
                if k.clustering_order.upper() != "NONE"
            ]
        )
        query += f"WITH CLUSTERING ORDER BY ({order})\n\t"
        query += f"AND bloom_filter_fp_chance = {self.bloom_filter_fp_chance}\n\t"
        query += f"AND caching = {self.caching}\n\t"
        query += f"AND comment = '{self.comment}'\n\t"
        query += f"AND compaction = {self.compaction}\n\t"
        query += f"AND compression = {self.compression}\n\t"
        query += f"AND crc_check_chance = {self.crc_check_chance}\n\t"
        query += f"AND gc_grace_seconds = {self.gc_grace_seconds}\n\t"
        query += f"AND max_index_interval = {self.max_index_interval}\n\t"
        query += f"AND memtable_flush_period_in_ms = {self.memtable_flush_period_in_ms}\n\t"
        query += f"AND min_index_interval = {self.min_index_interval}\n\t"
        query += f"AND speculative_retry = '{self.speculative_retry}';"

        if formatted is False:
            query = query.replace("\n\t", " ")
        return [query]


@dataclass
class TableMeta:
    """Table metadata."""

    id: UUID
    name: str
    table_name: str
    keyspace_name: str
    is_virtual: bool
    bloom_filter_fp_chance: float
    caching: Dict[str, str]
    comment: str
    compaction: Dict[str, str]
    compression: Dict[str, str]
    crc_check_chance: float
    dclocal_read_repair_chance: float
    default_time_to_live: int
    extensions: Dict[str, str]
    flags: Set[str]
    gc_grace_seconds: int
    max_index_interval: int
    memtable_flush_period_in_ms: int
    min_index_interval: int
    read_repair_chance: float
    speculative_retry: str
    columns: List[ColumnMeta]
    indexes: List[IndexMeta]
    materialized_views: List[MaterializedViewMeta]

    def as_cql_query(self, formatted=False, with_keyspace=True, full_schema=True) -> List[str]:
        """If full_schema is set to True returns a CQL query that can be used
        to recreate this table include indexes and materialized views creations.

        If formatted is set to True, extra whitespace will be added to make
        the query human readable.

        If with_keyspace is set to True, keyspace name will be added before
        table name in CREATE statement.
        For example CREATE TABLE keyspace_name.table_name... if with_keyspace
        is set to False, statement will be CREATE TABLE table_name..."""

        keyspace = f"{self.keyspace_name}."
        if with_keyspace is False:
            keyspace = ""
        query = f"CREATE TABLE {keyspace}{self.table_name} (\n\t"
        for colum in self.columns:
            query += f"{colum.name} {colum.type},\n\t"
        pk = ", ".join([k.column_name for k in self.columns if k.kind in ("partition_key", "clustering")])
        query += f"PRIMARY KEY ({pk})\n"
        order = ", ".join(
            [
                f"{k.column_name} {k.clustering_order.upper()}"
                for k in self.columns
                if k.clustering_order.upper() != "NONE"
            ]
        )
        if order:
            query += f") WITH CLUSTERING ORDER BY ({order})\n\t"
            query += f"AND bloom_filter_fp_chance = {self.bloom_filter_fp_chance}\n\t"
        else:
            query += f") WITH bloom_filter_fp_chance = {self.bloom_filter_fp_chance}\n\t"
        query += f"AND caching = {self.caching}\n\t"
        query += f"AND comment = '{self.comment}'\n\t"
        query += f"AND compaction = {self.compaction}\n\t"
        query += f"AND compression = {self.compression}\n\t"
        query += f"AND crc_check_chance = {self.crc_check_chance}\n\t"
        query += f"AND default_time_to_live = {self.default_time_to_live}\n\t"
        query += f"AND gc_grace_seconds = {self.gc_grace_seconds}\n\t"
        query += f"AND max_index_interval = {self.max_index_interval}\n\t"
        query += f"AND memtable_flush_period_in_ms = {self.memtable_flush_period_in_ms}\n\t"
        query += f"AND min_index_interval = {self.min_index_interval}\n\t"
        query += f"AND speculative_retry = '{self.speculative_retry}';"

        if formatted is False:
            query = query.replace("\n\t", " ").replace("( ", "(").replace("\n)", ")")
        query = [query]
        if full_schema is True:
            for index in self.indexes:
                query += index.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)
            for materialized_view in self.materialized_views:
                query += materialized_view.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)

        return query


@dataclass
class KeyspaceMeta:
    """Keyspace metadata."""

    name: str
    is_virtual: bool
    durable_writes: bool
    keyspace_name: str
    replication: Dict[str, str]
    user_types: List[UserTypeMeta]
    functions: List[FunctionMeta]
    aggregates: List[AggregateMeta]
    tables: List[TableMeta]

    def as_cql_query(self, formatted=False, with_keyspace=True, full_schema=True) -> List[str]:
        """If full_schema is set to True returns a CQL query string that can
        be used to recreate the entire keyspace including UDT, functions,
        tables, indexes and materialized views.

        If formatted is set to True, extra whitespace will be added to make
        the query more readable.

        If with_keyspace is set to True, keyspace name will be added before
        UDT name, function name, table name and materialized view name in
        CREATE statement.
        For example CREATE TABLE keyspace_name.table_name... if with_keyspace
        is set to False, statement will be CREATE TABLE table_name..."""

        query = [
            f"CREATE KEYSPACE {self.name} "
            f"WITH replication = {self.replication} "
            f"AND durable_writes = {self.durable_writes};"
        ]
        if full_schema is True:
            for user_type in self.user_types:
                query += user_type.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)
            for function in self.functions:
                query += function.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)
            for aggregate in self.aggregates:
                query += aggregate.as_cql_query(formatted=formatted, with_keyspace=with_keyspace)
            for table in self.tables:
                query += table.as_cql_query(formatted=formatted, with_keyspace=with_keyspace, full_schema=full_schema)
        return query
