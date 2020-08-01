import asyncio
import pytest

from acsylla import Cluster, create_statement
from acsylla.errors import (
    CassExceptionSyntaxError,
    CassExceptionInvalidQuery,
    CassExceptionConnectionError
)

pytestmark = pytest.mark.asyncio

class TestSession:
    async def test_create_session(self, host, keyspace):
        cluster = Cluster([host])
        session = await cluster.create_session(keyspace=keyspace)
        assert session is not None

        await session.close()

    async def test_create_session_without_keyspace(self, host):
        cluster = Cluster([host])
        session = await cluster.create_session()
        assert session is not None

        await session.close()

    async def test_create_session_invalid_host(self, keyspace):
        cluster = Cluster(["1.0.0.0"])
        with pytest.raises(CassExceptionConnectionError):
            session = await cluster.create_session(keyspace=keyspace)

    async def test_execute(self, session):
        key_and_value = "100"
        statement = create_statement(
            "INSERT INTO test (id, value) values(" + key_and_value + "," + key_and_value + ")")
        await session.execute(statement)

    async def test_execute_using_a_closed_session(self, session):
        await session.close()
        with pytest.raises(RuntimeError):
            await session.execute(create_statement("foobar"))

    async def test_execute_syntax_error(self, session):
        with pytest.raises(CassExceptionSyntaxError):
            await session.execute(create_statement("foobar"))

    async def test_execute_invalid_query(self, session):
        with pytest.raises(CassExceptionInvalidQuery):
            await session.execute(create_statement("CREATE TABLE foo(id invalid_type PRIMARY KEY)"))

    async def test_create_prepared(self, session):
        statement_str = "INSERT INTO test (id, value) values( ?, ?)"
        prepared = await session.create_prepared(statement_str)
        assert prepared is not None

    async def test_create_prepared_using_a_closed_session(self, session):
        await session.close()
        statement_str = "INSERT INTO test (id, value) values( ?, ?)"
        with pytest.raises(RuntimeError):
            await session.create_prepared(statement_str)
