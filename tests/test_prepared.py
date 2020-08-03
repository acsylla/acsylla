import pytest

pytestmark = pytest.mark.asyncio


class TestPreparedStatement:
    async def test_bind(self, session):
        statement_str = "INSERT INTO test (id, value) values( ?, ?)"
        prepared = await session.create_prepared(statement_str)
        statement = prepared.bind()
        assert statement is not None
