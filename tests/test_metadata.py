from acsylla import create_cluster
from acsylla import create_statement

import asyncio
import logging
import pytest

pytestmark = pytest.mark.asyncio(loop_scope="class")

logger = logging.getLogger(__name__)

# CQL keywords, as listed in cassandra.metadata.cql_keywords of the python driver
CQL_KEYWORDS = sorted(
    set(
        """
        add aggregate all allow alter and apply as asc ascii authorize batch begin
        bigint blob boolean by cast called clustering columnfamily compact contains count
        counter create custom date decimal default delete desc describe deterministic distinct double drop
        entries execute exists filtering finalfunc float from frozen full function
        functions grant if in index inet infinity initcond input insert int into is json
        key keys keyspace keyspaces language limit list login map materialized mbean mbeans modify monotonic
        nan nologin norecursive nosuperuser not null of on options or order password permission
        permissions primary rename replace returns revoke role roles schema scylla_clustering_bound
        scylla_counter_shard_list scylla_timeuuid_list_index select set sfunc smallint static storage stype superuser
        table text time timestamp timeuuid tinyint to token trigger truncate ttl tuple type unlogged
        unset update use user users using uuid values varchar varint view where with writetime
        node nodes plan active application applications java executor executors std_out std_err
        renew delegation no redact token lowercasestring cluster authentication schemes scheme
        internal ldap kerberos remote object method call calls search schema config rows
        columns profiles commit reload rebuild field workpool any submission indices
        restrict unrestrict
        """.split()
    )
)


class TestMeta:
    async def test_metadata_keyspace(self, session, keyspace):
        meta = session.get_metadata()
        assert keyspace in meta.get_keyspaces()
        assert keyspace == meta.get_keyspace_meta(keyspace).name

    async def test_metadata_user_types(self, session, keyspace):
        meta = session.get_metadata()
        assert "udt_type" in meta.get_user_types(keyspace)
        assert "udt_type" in [k.name for k in meta.get_user_types_meta(keyspace)]
        assert "udt_type" == meta.get_user_type_meta(keyspace, "udt_type").name

    async def test_metadata_tables(self, session, keyspace):
        meta = session.get_metadata()
        assert "test" in meta.get_tables(keyspace)
        assert "test" in [k.name for k in meta.get_tables_meta(keyspace)]
        assert "test" == meta.get_table_meta(keyspace, "test").name

    async def test_metadata_indexes(self, session, keyspace):
        meta = session.get_metadata()
        assert "test_index" in meta.get_indexes(keyspace)
        assert "test_index" in [k.name for k in meta.get_indexes_meta(keyspace)]
        assert "test_index" == meta.get_index_meta(keyspace, "test_index").name

    async def test_metadata_materialized_views(self, session, keyspace):
        meta = session.get_metadata()
        assert "test_materialized_view" in meta.get_materialized_views(keyspace)
        assert "test_materialized_view" in [k.name for k in meta.get_materialized_views_meta(keyspace)]
        assert "test_materialized_view" == meta.get_materialized_view_meta(keyspace, "test_materialized_view").name

    async def test_metadata_functions(self, session, keyspace):
        meta = session.get_metadata()
        assert ["avgfinal", "avgstate"] == meta.get_functions(keyspace)
        assert ["avgfinal", "avgstate"] == [k.name for k in meta.get_functions_meta(keyspace)]
        assert "avgfinal" == meta.get_function_meta(keyspace, "avgfinal").name

    async def test_metadata_aggregates(self, session, keyspace):
        meta = session.get_metadata()
        assert "average" in meta.get_aggregates(keyspace)
        assert "average" in [k.name for k in meta.get_aggregates_meta(keyspace)]
        assert "average" == meta.get_aggregate_meta(keyspace, "average").name

    async def test_recreate_keyspace_from_metadata(self, host, session, keyspace):
        new_keyspace = f"test_recteated_{keyspace}"
        meta = session.get_metadata()
        keyspace_meta = meta.get_keyspace_meta(keyspace)
        queries = keyspace_meta.as_cql_query(with_keyspace=False)
        await session.execute(create_statement(f"DROP KEYSPACE IF EXISTS {new_keyspace}"))
        create_keyspace = create_statement(queries.pop(0).replace(keyspace, new_keyspace))
        await session.execute(create_keyspace)
        await session.set_keyspace(new_keyspace)
        for query in queries:
            await session.execute(create_statement(query))
        await session.close()
        cluster = create_cluster([host])
        session = await cluster.create_session()
        new_meta = session.get_metadata()
        new_keyspace_meta = new_meta.get_keyspace_meta(new_keyspace)
        assert (
            new_keyspace_meta.as_cql_query(with_keyspace=False)[1:]
            == keyspace_meta.as_cql_query(with_keyspace=False)[1:]
        )

    async def test_recreate_keyspace_with_names_that_need_quoting(self, host):
        keyspace = "test_quoted_names"
        new_keyspace = f"test_recreated_{keyspace}"
        keyword_columns = ", ".join(f'"{keyword}" int' for keyword in CQL_KEYWORDS)
        keyword_fields = ", ".join(f'"{keyword}" text' for keyword in CQL_KEYWORDS)
        session = await create_cluster([host]).create_session()
        for name in (keyspace, new_keyspace):
            await session.execute(create_statement(f"DROP KEYSPACE IF EXISTS {name}"))
        for query in (
            f"CREATE KEYSPACE {keyspace} WITH REPLICATION = {{'class': 'SimpleStrategy', 'replication_factor': 1}}",
            f'CREATE TYPE {keyspace}."select" ({keyword_fields})',
            f'CREATE TYPE {keyspace}."MyType" ("from" frozen<"select">, "Items" frozen<list<frozen<"select">>>)',
            f'CREATE TABLE {keyspace}."order" ("Key" int, "Order" int, "MyVal" text, "Udt" frozen<"MyType">, '
            f'"UdtList" list<frozen<"select">>, {keyword_columns}, PRIMARY KEY ("Key", "Order")) '
            'WITH CLUSTERING ORDER BY ("Order" DESC)',
            f'CREATE TABLE {keyspace}."MyTable" (id int PRIMARY KEY, value text)',
            f'CREATE INDEX "index" ON {keyspace}."order" ("where")',
            f'CREATE INDEX "MyIndex" ON {keyspace}."order" ("MyVal")',
            f'CREATE MATERIALIZED VIEW {keyspace}."view" AS SELECT "Key", "Order", "MyVal", "select" '
            f'FROM {keyspace}."order" WHERE "Key" IS NOT NULL AND "Order" IS NOT NULL AND "MyVal" IS NOT NULL '
            'PRIMARY KEY ("MyVal", "Key", "Order")',
            f'CREATE FUNCTION {keyspace}."function"("select" int, "from" int) CALLED ON NULL INPUT RETURNS int '
            "LANGUAGE java AS 'return 0;'",
            f'CREATE FUNCTION {keyspace}."Final"("select" int) CALLED ON NULL INPUT RETURNS int '
            "LANGUAGE java AS 'return 0;'",
            f'CREATE AGGREGATE {keyspace}."aggregate"(int) SFUNC "function" STYPE int FINALFUNC "Final" INITCOND 0',
        ):
            await session.execute(create_statement(query))
        await session.close()

        session = await create_cluster([host]).create_session()
        meta = session.get_metadata()
        assert sorted(meta.get_user_types(keyspace)) == ["MyType", "select"]
        keyspace_meta = meta.get_keyspace_meta(keyspace)
        queries = keyspace_meta.as_cql_query(with_keyspace=False)
        await session.execute(create_statement(queries.pop(0).replace(keyspace, new_keyspace)))
        await session.set_keyspace(new_keyspace)
        for query in queries:
            await session.execute(create_statement(query))
        await session.close()

        session = await create_cluster([host]).create_session()
        new_meta = session.get_metadata()
        assert sorted(new_meta.get_tables(new_keyspace)) == ["MyTable", "order"]
        assert sorted(new_meta.get_user_types(new_keyspace)) == ["MyType", "select"]
        new_columns = [column.name for column in new_meta.get_table_meta(new_keyspace, "order").columns]
        assert set(CQL_KEYWORDS) <= set(new_columns)
        new_fields = [field.name for field in new_meta.get_user_type_meta(new_keyspace, "select").fields]
        assert set(CQL_KEYWORDS) == set(new_fields)
        assert (
            new_meta.get_keyspace_meta(new_keyspace).as_cql_query(with_keyspace=False)[1:]
            == keyspace_meta.as_cql_query(with_keyspace=False)[1:]
        )
        await session.close()
