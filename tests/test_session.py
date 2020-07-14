import asyncio
import pytest

from acsylla import Cluster, Statement
from acsylla.errors import CassExceptionSyntaxError

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

    @pytest.mark.xfail(reason="Needs investigation")
    async def test_create_session_invalid_host(self, keyspace):
        cluster = Cluster(["127.0.0.2"])
        with pytest.raises(Exception):
            session = await cluster.create_session(keyspace=keyspace)

    async def test_execute(self, session):
        key_and_value = "100"
        statement = Statement(
            "INSERT INTO test (id, value) values(" + key_and_value + "," + key_and_value + ")")
        await session.execute(statement)

    async def test_execute_using_a_closed_session(self, session):
        await session.close()
        with pytest.raises(RuntimeError):
            await session.execute(Statement("foobar"))

    async def test_execute_syntax_error(self, session):
        with pytest.raises(CassExceptionSyntaxError):
            await session.execute(Statement("foobar"))
