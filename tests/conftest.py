import asyncio
import pytest

from acsylla import Cluster

@pytest.fixture
def keyspace():
    return "acsylla"

@pytest.fixture
def host():
    return "127.0.0.1"

@pytest.fixture
async def cluster(event_loop, host):
    return Cluster([host])

@pytest.fixture
async def session(event_loop, cluster, keyspace):
    # Create the acsylla keyspace if it does not exist yet
    session_without_keyspace = await cluster.create_session()
    create_keyspace_statement = \
        "CREATE KEYSPACE IF NOT EXISTS {} WITH REPLICATION = ".format(keyspace) +\
        "{ 'class': 'SimpleStrategy', 'replication_factor': 1}"
    await session_without_keyspace.execute(create_keyspace_statement.encode())
    await session_without_keyspace.close()

    # Create the table test in the acsylla keyspace
    session = await cluster.create_session(keyspace=keyspace)
    create_table_statement = \
        "CREATE TABLE IF NOT EXISTS test(id int PRIMARY KEY, value int)"
    await session.execute(create_table_statement.encode())

    try:
        yield session
    finally:
        await session.close()
