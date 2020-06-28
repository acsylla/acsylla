import pytest
from acsylla import Cluster

pytestmark = pytest.mark.asyncio

async def test_write():
    cluster = Cluster()
    session = await cluster.create_session()
    for _ in range(100):
        await session.write()
