from acsylla import Consistency

import pytest

pytestmark = pytest.mark.asyncio


class TestPreparedStatement:
    async def test_create_with_timeout(self, session):
        statement_str = "INSERT INTO test (id, value) values( ?, ?)"
        prepared = await session.create_prepared(statement_str, timeout=1.0)
        assert prepared is not None

    @pytest.mark.parametrize(
        "consistency",
        [
            Consistency.ANY,
            Consistency.ONE,
            Consistency.TWO,
            Consistency.THREE,
            Consistency.QUORUM,
            Consistency.ALL,
            Consistency.LOCAL_QUORUM,
            Consistency.EACH_QUORUM,
            Consistency.SERIAL,
            Consistency.LOCAL_SERIAL,
            Consistency.LOCAL_ONE,
        ],
    )
    async def test_create_with_consistency(self, session, consistency):
        statement_str = "INSERT INTO test (id, value) values( ?, ?)"
        prepared = await session.create_prepared(statement_str, consistency=consistency, serial_consistency=consistency)
        assert prepared is not None

    async def test_bind(self, session):
        statement_str = "INSERT INTO test (id, value) values( ?, ?)"
        prepared = await session.create_prepared(statement_str)
        statement = prepared.bind()
        assert statement is not None

    async def test_statement_with_execution_profile(self, session):
        statement_str = "INSERT INTO test (id, value) values( ?, ?)"
        prepared = await session.create_prepared(statement_str)
        statement = prepared.bind(execution_profile="")
        statement.set_execution_profile("")
        assert statement is not None

    async def test_async_generator(self, session):
        statement_str = "INSERT INTO test (id, value) values( ?, ?)"
        prepared = await session.create_prepared(statement_str)
        for i in range(100):
            await prepared.bind([i, i]).execute()
            # await prepared.bind((i,i)).execute()
            await prepared.bind({"id": i, "value": i}).execute()

        statement_str = "SELECT id, value FROM test"
        prepared = await session.create_prepared(statement_str)
        values_list = range(100)
        async for row in prepared.bind():
            assert row[1] in values_list
            assert row["value"] in values_list
