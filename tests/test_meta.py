from acsylla import create_cluster
from acsylla import create_statement

import pytest

pytestmark = pytest.mark.asyncio


class TestMeta:
    async def test_meta(self, session, keyspace):
        assert keyspace in session.meta.keyspaces_names()
        assert keyspace == session.meta.keyspace(keyspace).name

        assert "udt_type" in session.meta.user_types_names(keyspace)
        assert "udt_type" in [k.name for k in session.meta.user_types(keyspace)]
        assert "udt_type" == session.meta.user_type(keyspace, "udt_type").name

        assert "test" in session.meta.tables_names(keyspace)
        assert "test" in [k.name for k in session.meta.tables(keyspace)]
        assert "test" == session.meta.table(keyspace, "test").name

        assert "test_index" in session.meta.indexes_names(keyspace)
        assert "test_index" in [k.name for k in session.meta.indexes(keyspace)]
        assert "test_index" == session.meta.index(keyspace, "test_index").name

        assert "test_materialized_view" in session.meta.materialized_views_names(keyspace)
        assert "test_materialized_view" in [k.name for k in session.meta.materialized_views(keyspace)]
        assert "test_materialized_view" == session.meta.materialized_view(keyspace, "test_materialized_view").name

        assert ["avgfinal", "avgstate"] == session.meta.functions_names(keyspace)
        assert ["avgfinal", "avgstate"] == [k.name for k in session.meta.functions(keyspace)]
        assert "avgfinal" == session.meta.function(keyspace, "avgfinal").name

        assert "average" in session.meta.aggregates_names(keyspace)
        assert "average" in [k.name for k in session.meta.aggregates(keyspace)]
        assert "average" == session.meta.aggregate(keyspace, "average").name

    async def test_recreate_keyspace(self, host, session, keyspace):
        new_keyspace = f"test_recteated_{keyspace}"
        keyspace_meta = session.meta.keyspace(keyspace)
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
        new_keyspace_meta = session.meta.keyspace(new_keyspace)
        assert (
            new_keyspace_meta.as_cql_query(with_keyspace=False)[1:]
            == keyspace_meta.as_cql_query(with_keyspace=False)[1:]
        )
