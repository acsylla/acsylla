import asyncio
import pytest

from acsylla import Cluster

KEYSPACE = "acsylla"

@pytest.fixture
async def cluster(event_loop):
    return Cluster(["127.0.0.1"])

@pytest.fixture
async def session(event_loop, cluster):
    session = await cluster.create_session(keyspace=KEYSPACE)
    try:
        yield session
    finally:
        await session.close()


