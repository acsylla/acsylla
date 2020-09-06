from acsylla import create_batch_unlogged, create_cluster, create_statement
from acsylla.errors import CassErrorLibNoHostsAvailable, CassErrorServerInvalidQuery, CassErrorServerSyntaxError

import pytest

pytestmark = pytest.mark.asyncio


class TestSession:
    async def test_create_session(self, host, keyspace):
        cluster = create_cluster([host])
        session = await cluster.create_session(keyspace=keyspace)
        assert session is not None

        await session.close()

    async def test_create_session_without_keyspace(self, host):
        cluster = create_cluster([host])
        session = await cluster.create_session()
        assert session is not None

        await session.close()

    async def test_create_session_invalid_host(self, keyspace):
        cluster = create_cluster(["1.0.0.0"])
        with pytest.raises(CassErrorLibNoHostsAvailable):
            await cluster.create_session(keyspace=keyspace)

    async def test_execute(self, session, id_generation):
        key_and_value = str(next(id_generation))
        statement = create_statement("INSERT INTO test (id, value) values(" + key_and_value + "," + key_and_value + ")")
        await session.execute(statement)

    async def test_execute_using_a_closed_session(self, session):
        await session.close()
        with pytest.raises(RuntimeError):
            await session.execute(create_statement("foobar"))

    async def test_execute_syntax_error(self, session):
        with pytest.raises(CassErrorServerSyntaxError):
            await session.execute(create_statement("foobar"))

    async def test_execute_invalid_query(self, session):
        with pytest.raises(CassErrorServerInvalidQuery):
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

    async def test_execute_batch(self, session, id_generation):
        batch = create_batch_unlogged()
        key_and_value = str(next(id_generation))
        batch.add_statement(
            create_statement("INSERT INTO test (id, value) values(" + key_and_value + "," + key_and_value + ")")
        )
        key_and_value = str(next(id_generation))
        batch.add_statement(
            create_statement("INSERT INTO test (id, value) values(" + key_and_value + "," + key_and_value + ")")
        )
        await session.execute_batch(batch)

    async def test_execute_batch_using_a_closed_session(self, session):
        await session.close()
        with pytest.raises(RuntimeError):
            await session.execute_batch(create_batch_unlogged())
