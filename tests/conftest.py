import asyncio
import pytest
import time

from acsylla import Cluster, Statement

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
    create_keyspace_statement = Statement(
        "CREATE KEYSPACE IF NOT EXISTS {} WITH REPLICATION = ".format(keyspace) +
        "{ 'class': 'SimpleStrategy', 'replication_factor': 1}"
    )
    await session_without_keyspace.execute(create_keyspace_statement)
    await session_without_keyspace.close()

    # Create the table test in the acsylla keyspace
    session = await cluster.create_session(keyspace=keyspace)
    create_table_statement = Statement(
        "CREATE TABLE IF NOT EXISTS test(id int PRIMARY KEY, value int)")
    await session.execute(create_table_statement)

    # Truncate table
    create_table_statement = Statement(
        "TRUNCATE TABLE test")
    await session.execute(create_table_statement)

    try:
        yield session
    finally:
        await session.close()

@pytest.fixture(scope="session")
def id_generation():
    def _():
        cnt = 1
        while True:
            yield cnt
            cnt += 1

    return _()
