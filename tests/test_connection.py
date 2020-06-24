import pytest
from acsylla import Cluster

pytestmark = pytest.mark.asyncio

async def test_connect():
    cluster = Cluster()
    session = await cluster.create_session()
