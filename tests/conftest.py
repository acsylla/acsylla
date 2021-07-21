from acsylla import create_cluster, create_statement

import pytest


@pytest.fixture
def keyspace():
    return "acsylla"


@pytest.fixture
def host():
    return "127.0.0.1"


@pytest.fixture
async def cluster(event_loop, host):
    return create_cluster([host], connect_timeout=5.0, request_timeout=5.0, resolve_timeout=5.0)


@pytest.fixture
async def session(event_loop, cluster, keyspace):
    # Create the acsylla keyspace if it does not exist yet
    session_without_keyspace = await cluster.create_session()
    create_keyspace_statement = create_statement(
        "CREATE KEYSPACE IF NOT EXISTS {} WITH REPLICATION = ".format(keyspace)
        + "{ 'class': 'SimpleStrategy', 'replication_factor': 1}"
    )
    await session_without_keyspace.execute(create_keyspace_statement)
    await session_without_keyspace.close()

    session = await cluster.create_session(keyspace=keyspace)

    # Drop table if exits, will truncate any data used before
    # and will enforce in the next step that if the schema of
    # table changed is used during the tests.
    create_table_statement = create_statement("DROP TABLE IF EXISTS test")
    await session.execute(create_table_statement)

    # Create the table test in the acsylla keyspace
    create_table_statement = create_statement('''
        CREATE TABLE test (
            id int PRIMARY KEY,
            value int,
            value_int int,
            value_float float,
            value_bool boolean,
            value_text text,
            value_blob blob,
            value_uuid uuid,
            
            value_ascii ascii,
            value_bigint bigint,
            value_date date,
            value_decimal decimal,
            value_double double,
            value_duration duration,
            value_inet inet,
            value_smallint smallint,
            value_time time,
            value_timestamp timestamp,
            value_timeuuid timeuuid,
            value_tinyint tinyint,
            value_varchar varchar,
            value_varint varint,
            value_map_text_bigint map<text, bigint>)
    ''')
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
