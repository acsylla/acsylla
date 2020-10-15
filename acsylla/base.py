"""Abstract base classes, use them for documentation or for adding
types in your functions."""
from abc import ABCMeta, abstractmethod
from acsylla._cython import cyacsylla
from dataclasses import dataclass
from enum import Enum
from typing import Iterable, Optional


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
        """ Closes a session.

        After calling this method no more executions will be allowed
        raising the proper excetion if this is the case.
        """

    @abstractmethod
    async def execute(self, statement: "Statement") -> "Result":
        """ Executes an statement and returns the result."""

    @abstractmethod
    async def create_prepared(self, statement: str, timeout: Optional[float] = None) -> "PreparedStatement":
        """ Prepares an statement.

        By providing a `timeout` all requests built by the prepared statement will use it,
        otherwise timeout provided during the Cluster instantantation will be used. Value expected is seconds.
        """

    @abstractmethod
    async def execute_batch(self, batch: "Batch") -> None:
        """ Executes a batch of statements."""

    @abstractmethod
    async def metrics(self) -> "SessionMetrics":
        """ Returns the metrics related to the session."""


class Statement(metaclass=ABCMeta):
    """Provides a Statement instance class. Use the the
    `create_statement` factory for creating a new instance"""

    @abstractmethod
    def bind_null(self, index: int) -> None:
        """ Binds the `null` value to a specific index parameter."""

    @abstractmethod
    def bind_int(self, index: int, value: int) -> None:
        """ Binds the int value to a specific index parameter."""

    @abstractmethod
    def bind_float(self, index: int, value: float) -> None:
        """ Binds the float value to a specific index parameter."""

    @abstractmethod
    def bind_bool(self, index: int, value: bool) -> None:
        """ Binds the bool value to a specific index parameter."""

    @abstractmethod
    def bind_string(self, index: int, value: str) -> None:
        """ Binds the str value to a specific index parameter."""

    @abstractmethod
    def bind_bytes(self, index: int, value: bytes) -> None:
        """ Binds the bytes value to a specific index parameter."""

    @abstractmethod
    def bind_uuid(self, index: int, value: str) -> None:
        """ Binds the str value of a uuid to a specific index parameter."""

    # following methods are only allowed for statements
    # created using prepared statements

    @abstractmethod
    def bind_null_by_name(self, name: str) -> None:
        """ Binds the `null` value to a specific parameter."""

    @abstractmethod
    def bind_int_by_name(self, name: str, value: int) -> None:
        """ Binds the int value to a specific parameter."""

    @abstractmethod
    def bind_float_by_name(self, name: str, value: float) -> None:
        """ Binds the float value to a specific parameter."""

    @abstractmethod
    def bind_bool_by_name(self, name: str, value: bool) -> None:
        """ Binds the bool value to a specific parameter."""

    @abstractmethod
    def bind_string_by_name(self, name: str, value: str) -> None:
        """ Binds the str value to a specific parameter."""

    @abstractmethod
    def bind_bytes_by_name(self, name: str, value: bytes) -> None:
        """ Binds the bytes value to a specific parameter."""

    @abstractmethod
    def bind_uuid_by_name(self, name: str, value: str) -> None:
        """ Binds the str value for a uuid to a specific index parameter."""


class PreparedStatement(metaclass=ABCMeta):
    """Provides a PreparedStatement instance class. Use the
    `session.create_prepared()` coroutine for creating a new instance"""

    @abstractmethod
    def bind(self, page_size: Optional[int] = None, page_state: Optional[bytes] = None) -> Statement:
        """ Returns a new statment using the prepared."""


class Batch(metaclass=ABCMeta):
    """Provides a Batch instance class. Use the
    `create_batch_logged()` and `create_batch_unlogged` factories
    for creating a new instance."""

    @abstractmethod
    def add_statement(self, statement: Statement) -> None:
        """ Adds a new statement to the batch."""


class Result(metaclass=ABCMeta):
    """Provides a result instance class. Use the
    `session.execute()` coroutine for getting the result
    from a query"""

    @abstractmethod
    def count(self) -> int:
        """ Returns the total rows of the result"""

    @abstractmethod
    def column_count(self) -> int:
        """ Returns the total columns returned"""

    @abstractmethod
    def first(self) -> Optional["Row"]:
        """ Return the first result, if there is no row
        returns None.
        """

    @abstractmethod
    def all(self) -> Iterable["Row"]:
        """ Return the all rows using of a result, using an
        iterator.

        If there is no rows iterator returns no rows.
        """

    @abstractmethod
    def has_more_pages(self) -> bool:
        """ Returns true if there is still pages to be fetched"""

    @abstractmethod
    def page_state(self) -> bytes:
        """ Returns a token with the page state for continuing fetching
        new results.

        Before calling this method you must first checks if there are more
        results using the `has_more_pages` function, and if there are use the
        token returned by this function as an argument of the factories for creating
        an statement for returning the next page.
        """


class Row(metaclass=ABCMeta):
    """Provides access to a row of a `Result`"""

    @abstractmethod
    def column_by_name(self, name: str) -> "Value":
        """ Returns the row column value called by `name`.

        Raises a `CassException` derived exception if the column can not be found"""


class Value(metaclass=ABCMeta):
    """Provides access to a column value of a `Row`"""

    @abstractmethod
    def int(self) -> int:
        """ Returns the int value associated to a column."""

    @abstractmethod
    def bool(self) -> bool:
        """ Returns the bool value associated to a column."""

    @abstractmethod
    def float(self) -> float:
        """ Returns the float value associated to a column."""

    @abstractmethod
    def string(self) -> str:
        """ Returns the string value associated to a column."""

    @abstractmethod
    def bytes(self) -> bytes:
        """ Returns the bytes value associated to a column."""

    @abstractmethod
    def uuid(self) -> str:
        """ Returns the str value of the uuid associated to a column."""


@dataclass
class SessionMetrics:
    """ Provides basic metrics for the Session."""

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
