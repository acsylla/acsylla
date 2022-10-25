from acsylla import create_cluster
from acsylla import create_statement

import pytest

pytestmark = pytest.mark.asyncio


class TestMeta:
    async def test_metadata(self, session, keyspace):
        meta = session.get_metadata()
        assert keyspace in meta.get_keyspaces()
        assert keyspace == meta.get_keyspace_meta(keyspace).name

        assert "udt_type" in meta.get_user_types(keyspace)
        assert "udt_type" in [k.name for k in meta.get_user_types_meta(keyspace)]
        assert "udt_type" == meta.get_user_type_meta(keyspace, "udt_type").name

        assert "test" in meta.get_tables(keyspace)
        assert "test" in [k.name for k in meta.get_tables_meta(keyspace)]
        assert "test" == meta.get_table_meta(keyspace, "test").name

        assert "test_index" in meta.get_indexes(keyspace)
        assert "test_index" in [k.name for k in meta.get_indexes_meta(keyspace)]
        assert "test_index" == meta.get_index_meta(keyspace, "test_index").name

        assert "test_materialized_view" in meta.get_materialized_views(keyspace)
        assert "test_materialized_view" in [k.name for k in meta.get_materialized_views_meta(keyspace)]
        assert "test_materialized_view" == meta.get_materialized_view_meta(keyspace, "test_materialized_view").name

        assert ["avgfinal", "avgstate"] == meta.get_functions(keyspace)
        assert ["avgfinal", "avgstate"] == [k.name for k in meta.get_functions_meta(keyspace)]
        assert "avgfinal" == meta.get_function_meta(keyspace, "avgfinal").name

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
