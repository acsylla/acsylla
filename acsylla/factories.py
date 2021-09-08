from . import _cython
from .base import (
    Batch,
    Cluster,
    Consistency,
    Statement,
)
from .version import __version__
from typing import List, Optional


def create_cluster(
    contact_points: List[str],
    port: int = 9042,
    protocol_version: int = 3,
    connect_timeout: float = 5.0,
    request_timeout: float = 2.0,
    resolve_timeout: float = 1.0,
    consistency: Consistency = Consistency.LOCAL_ONE,
    core_connections_per_host: int = 1,
    local_port_range_min: int = 49152,
    local_port_range_max: int = 65535,
    application_name: str = "acsylla",
    application_version: str = __version__,
    num_threads_io: int = 1,
) -> Cluster:
    """Instanciates a new cluster.

    Provide a list of `contact_points` for using them as a first list of cluster nodes for using
    them as a first list of contacting nodes.

    By default `protocol_version` 3 is used, if you want to specify another protocol version
    you must provide a different value.

    If `connect_timeout`, `request_timeout` or `resolve_timeout` are provided they will
    override the default values. Values provided are in seconds.

    If `consistency` is provided the default value would be override, any statment will use
    by default that consistency level unless it is specificily configured at statement level.
    """
    return _cython.cyacsylla.Cluster(
        contact_points,
        port,
        protocol_version,
        connect_timeout,
        request_timeout,
        resolve_timeout,
        consistency,
        core_connections_per_host,
        local_port_range_min,
        local_port_range_max,
        application_name,
        application_version,
        num_threads_io,
    )


def create_statement(
    statement: str,
    parameters: int = 0,
    page_size: Optional[int] = None,
    page_state: Optional[bytes] = None,
    timeout: Optional[float] = None,
    consistency: Optional[Consistency] = None,
) -> Statement:
    """
    Creates a new statment.

    Provide a raw `statement` and the number of `parameters` if there are, othewise will default to
    0.

    Pagination can be handled by providing a `page_size` for telling the maximum size of records
    fetched. The `page_state` will act as a cursor by returning the next results of a previous
    execution.

    If `timeout` is provided, this will override the request timeout provided during the cluster
    creation. Value expected is in seconds.

    If `consistency` is provided, this will override the consistency value provided during the cluster
    creation.
    """
    return _cython.cyacsylla.create_statement(
        statement,
        parameters=parameters,
        page_size=page_size,
        page_state=page_state,
        timeout=timeout,
        consistency=consistency,
    )


def create_batch_logged(timeout: Optional[float] = None) -> Batch:
    """
    Creates a new batch logged.

    If `timeout` is provided, this will override the request timeout provided during the cluster
    creation. Value expected is in seconds.
    """
    return _cython.cyacsylla.create_batch_logged(timeout)


def create_batch_unlogged(timeout: Optional[float] = None) -> Batch:
    """
    Creates a new batch unlogged.

    If `timeout` is provided, this will override the request timeout provided during the cluster
    creation. Value expected is in seconds.
    """
    return _cython.cyacsylla.create_batch_unlogged(timeout)


def create_batch_counter(timeout: Optional[float] = None) -> Batch:
    """
    Creates a new batch counter.

    If `timeout` is provided, this will override the request timeout provided during the cluster
    creation. Value expected is in seconds.
    """
    return _cython.cyacsylla.create_batch_counter(timeout)
