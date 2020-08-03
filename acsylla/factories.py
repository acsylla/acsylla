from . import _cython
from .base import Batch, Cluster, Statement
from typing import List


def create_cluster(contact_points: List[str], protocol_version: int = 3) -> Cluster:
    return _cython.cyacsylla.Cluster(contact_points, protocol_version=protocol_version)


def create_statement(statement: str, parameters: int = 0) -> Statement:
    return _cython.cyacsylla.create_statement(statement, parameters=parameters)


def create_batch_logged() -> Batch:
    return _cython.cyacsylla.create_batch_logged()


def create_batch_unlogged() -> Batch:
    return _cython.cyacsylla.create_batch_logged()
