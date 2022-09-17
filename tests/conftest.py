from acsylla import create_cluster
from acsylla import create_statement

import os
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
        f"CREATE KEYSPACE IF NOT EXISTS {keyspace} WITH REPLICATION = "
        "{ 'class': 'SimpleStrategy', 'replication_factor': 1}"
    )
    await session_without_keyspace.execute(create_keyspace_statement)
    await session_without_keyspace.close()

    session = await cluster.create_session(keyspace=keyspace)

    # Drop table if exits, will truncate any data used before
    # and will enforce in the next step that if the schema of
    # table changed is used during the tests.
    create_table_statement = create_statement("DROP MATERIALIZED VIEW IF EXISTS test_materialized_view")
    await session.execute(create_table_statement)
    create_table_statement = create_statement("DROP INDEX IF EXISTS test_index")
    await session.execute(create_table_statement)
    create_table_statement = create_statement("DROP TABLE IF EXISTS test")
    await session.execute(create_table_statement)
    create_table_statement = create_statement("DROP TYPE IF EXISTS udt_type")
    await session.execute(create_table_statement)
    create_table_statement = create_statement("DROP TYPE IF EXISTS udt_nested_type")
    await session.execute(create_table_statement)
    create_table_statement = create_statement(
        """
    CREATE TYPE udt_nested_type (
        value_ascii ascii,
        value_bigint bigint,
    );
    """
    )
    await session.execute(create_table_statement)
    create_table_statement = create_statement(
        """
    CREATE TYPE udt_type (
            value_ascii ascii,
            value_bigint bigint,
            value_blob blob,
            value_boolean boolean,
            value_date date,
            value_decimal decimal,
            value_double double,
            value_duration duration,
            value_float float,
            value_inet inet,
            value_int int,
            value_smallint smallint,
            value_text text,
            value_time time,
            value_timestamp timestamp,
            value_timeuuid timeuuid,
            value_tinyint tinyint,
            value_varchar varchar,
            value_varint varint,
            value_map_text_bigint map<text, bigint>,
            value_set_text set<text>,
            value_list_text list<text>,
            value_tuple_text_bigint tuple<text, bigint>,
            value_nested_udt frozen<udt_nested_type>
    );
    """
    )
    await session.execute(create_table_statement)

    # Create the table test in the acsylla keyspace
    create_table_statement = create_statement(
        """
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
            value_map_text_bigint map<text, bigint>,
            value_set_text set<text>,
            value_list_text list<text>,
            value_tuple_text_bigint tuple<text, bigint>,
            value_udt frozen<udt_type>,
            value_list_udt list<frozen<udt_type>>,
            value_set_udt set<frozen<udt_type>>,
            value_map_udt map<bigint, frozen<udt_type>>,
            value_tuple_udt tuple<frozen<udt_type>, frozen<udt_nested_type>>,
        );
    """
    )
    await session.execute(create_table_statement)

    additional_statements = [
        create_statement(
            """
            CREATE OR REPLACE FUNCTION avgstate ( state tuple<int,bigint>, val int )
            CALLED ON NULL INPUT
            RETURNS tuple<int,bigint>
            LANGUAGE java AS  $$
                if (val !=null) {
                      state.setInt(0, state.getInt(0)+1);
                      state.setLong(1, state.getLong(1)+val.intValue());
                      }
                   return state;
            $$;"""
        ),
        create_statement(
            """
            CREATE OR REPLACE FUNCTION avgfinal ( state tuple<int,bigint> )
            CALLED ON NULL INPUT
            RETURNS double
            LANGUAGE java AS $$
                double r = 0;
                if (state.getInt(0) == 0) return null;
                r = state.getLong(1);
                r = state.getInt(0);
                return Double.valueOf(r);
            $$;"""
        ),
        create_statement(
            """
            CREATE OR REPLACE AGGREGATE average(int)
            SFUNC avgState
            STYPE tuple<int,bigint>
            FINALFUNC avgFinal
            INITCOND (0,0);"""
        ),
        create_statement(
            """
            CREATE INDEX test_index ON test (value_text);
        """
        ),
        create_statement(
            """
            CREATE MATERIALIZED VIEW test_materialized_view
            AS SELECT * FROM test
            WHERE id IS NOT null AND value_bool IS NOT NULL PRIMARY KEY (id, value_bool);
        """
        ),
    ]

    for statement in additional_statements:
        await session.execute(statement)

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


@pytest.fixture
def certificates():
    path = os.path.join(os.path.dirname(__file__), "../certs")
    with open(f"{path}/client.cert.pem") as f:
        ssl_cert = f.read()
    with open(f"{path}/client.key.pem") as f:
        ssl_private_key = f.read()
    with open(f"{path}/trusted.cert.pem") as f:
        ssl_trusted_cert = f.read()

    return ssl_cert, ssl_private_key, ssl_trusted_cert
