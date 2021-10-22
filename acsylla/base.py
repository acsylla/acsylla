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
from typing import Iterable
from typing import Mapping
from typing import Optional
from typing import Sequence
from typing import Union
from uuid import UUID

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


class Session(metaclass=ABCMeta):
    """Provides a Session instance class. Use the the
    `Cluster.create_session` coroutine for creating a new instance"""

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
    def column_value(self, name: str) -> SupportedType:
        """Returns the row column value called by `name`.

        Raises a `CassException` derived exception if the column can not be found

        Type is inferred by using the Cassandra driver
        and converted, if supported, to a Python type or one
        of the extended types provided by Acsylla.

        Types support for now: None, bool, int, float, str, bytes, and UUID.
        """


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
