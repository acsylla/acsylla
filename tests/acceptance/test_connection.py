import pytest

pytestmark = pytest.mark.asyncio

async def test_connect(cluster):
    await cluster.create_session(keyspace='acsyllas')
