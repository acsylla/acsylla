import pytest

pytestmark = pytest.mark.asyncio

async def test_write(session):
    for key_and_value in range(100):
        key_and_value = str(key_and_value).encode()
        statement = b"INSERT INTO test (id, value) values(" + key_and_value + b"," + key_and_value + b")"
        await session.execute(statement)
