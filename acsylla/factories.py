from . import _cython
from .base import Batch
from .base import Cluster
from .base import Consistency
from .base import SSLVerifyFlags
from .base import Statement
from .version import __version__
from typing import List
from typing import Optional


def create_cluster(
    contact_points: List[str],
    port: int = 9042,
    username: str = None,
    password: str = None,
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
    ssl_enabled: bool = False,
    ssl_cert: str = None,
    ssl_private_key: str = None,
    ssl_private_key_password: str = "",
    ssl_trusted_cert: str = None,
    ssl_verify_flags: SSLVerifyFlags = SSLVerifyFlags.PEER_CERT,
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

    Set `ssl_enable` for use SSL

    `ssl_cert` Set client-side certificate chain. This is used to authenticate the client on the server-side.
        This should contain the entire Certificate chain starting with the certificate itself

    `ssl_private_key` Set client-side private key. This is used to authenticate the client on the server-side.

    `ssl_private_key_password` Password for `ssl_private_key`

    `ssl_trusted_cert` Adds a trusted certificate. This is used to verify the peer’s certificate.

    `ssl_verify_flags` Sets verification performed on the peer’s certificate.
        SSLVerifyFlags.NONE - No verification is performed
        SSLVerifyFlags.PEER_CERT - Certificate is present and valid
        SSLVerifyFlags.PEER_IDENTITY - IP address matches the certificate’s common name or one
            of its subject alternative names. This implies the certificate is also present.
        SSLVerifyFlags.PEER_IDENTITY_DNS - Hostname matches the certificate’s common name or
            one of its subject alternative names. This implies the certificate is
            also present. Hostname resolution must also be enabled.
        Default: SSLVerifyFlags.PEER_CERT
    """
    return _cython.cyacsylla.Cluster(
        contact_points,
        port,
        protocol_version,
        username,
        password,
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
        ssl_enabled,
        ssl_cert,
        ssl_private_key,
        ssl_private_key_password,
        ssl_trusted_cert,
        ssl_verify_flags,
    )


def create_statement(
    statement: str,
    parameters: int = 0,
    page_size: Optional[int] = None,
    page_state: Optional[bytes] = None,
    timeout: Optional[float] = None,
    consistency: Optional[Consistency] = None,
    serial_consistency: Optional[Consistency] = None,
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
        serial_consistency=serial_consistency,
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
