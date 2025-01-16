from . import cql_types
from acsylla import ValueType

import asyncio
import logging
import pytest
import random

pytestmark = pytest.mark.asyncio(loop_scope="class")


class TestQueryTypesHint:
    @pytest.fixture(scope='class', autouse=True, params=sorted(set(cql_types.native_types)))
    async def data_type(self, request):
        return request.param

    def select_query(self, column, table):
        return f"SELECT {column} FROM test_{table} WHERE id=?"

    @pytest.mark.parametrize(
        "bind_type",
        [list, tuple, dict],
    )
    async def test_bind_value_with_value_types(self, bind_type, data_type, session, id_generation):
        _id = next(id_generation)
        insert_query = cql_types.insert_query("native", data_type)
        native_type = cql_types.native_types[data_type]
        value = native_type["valid"][0][0]
        expected_value = native_type["valid"][0][1]
        if isinstance(expected_value, (tuple, list)):
            expected_value = expected_value[1]
        value_type = native_type["value_type"]
        column = f"value_{data_type}"
        if bind_type is dict:
            bind_values = {"id": _id, column: value}
            bind_values_types = {"id": ValueType.INT, column: value_type}
        else:
            bind_values = bind_type([_id, value])
            bind_values_types = bind_type([ValueType.INT, value_type])
        await session.query(insert_query, bind_values, bind_values_types)
        select_query = self.select_query(column, "native")
        async for row in session.query(select_query, (_id,)):
            assert dict(row) == {column: expected_value}


class TestPythonicSession:
    @pytest.fixture(scope='class', autouse=True)
    def select_query(self):
        return "SELECT id, value FROM test WHERE id=?"

    @pytest.fixture(scope='class', autouse=True)
    def insert_query(self):
        return "INSERT INTO test (id, value) values( ?, ?)"

    @pytest.mark.parametrize(
        "bind_type",
        [list, tuple, dict],
    )
    async def test_query(self, session, id_generation, bind_type, insert_query, select_query):
        _id = next(id_generation)
        value = random.randint(1, 100000)
        expected_dict = dict(id=_id, value=value)
        if bind_type is dict:
            bind_values = expected_dict
            bind_value_id = dict(id=_id)
        else:
            bind_values = bind_type([_id, value])
            bind_value_id = bind_type([_id])
        await session.query(insert_query, bind_values)
        result = await session.query(select_query, bind_value_id)
        assert len(result) == 1
        assert dict(result.first()) == expected_dict
        async for row in session.query(select_query, bind_value_id):
            assert dict(row) == expected_dict
        statement = session.query(select_query, (_id,))
        result = await session.execute(statement)
        assert len(result) == 1
        assert dict(result.first()) == expected_dict

    @pytest.mark.parametrize(
        "bind_type",
        [list, tuple, dict],
    )
    async def test_call_to_statement_object(self, session, id_generation, bind_type, insert_query, select_query):
        _id = next(id_generation)
        value = random.randint(1, 100000)
        expected_dict = dict(id=_id, value=value)
        if bind_type is dict:
            bind_values = expected_dict
            bind_value_id = dict(id=_id)
        else:
            bind_values = bind_type([_id, value])
            bind_value_id = bind_type([_id])

        insert = session.query(insert_query)
        await insert(bind_values)

        select = session.query(select_query)
        result = await select(bind_value_id)
        assert len(result) == 1
        assert dict(result.first()) == expected_dict

        query = session.query(select_query)
        async for row in query(bind_value_id):
            assert dict(row) == expected_dict
        statement = session.query(select_query)
        result = await statement((_id,))
        assert len(result) == 1
        assert dict(result.first()) == expected_dict

    @pytest.mark.parametrize(
        "bind_type",
        [list, tuple, dict],
    )
    async def test_prepared(self, session, id_generation, bind_type, insert_query, select_query):
        id = next(id_generation)
        value = random.randint(1, 100000)
        expected_dict = dict(id=id, value=value)
        if bind_type is dict:
            bind_values = expected_dict
            bind_value_id = dict(id=id)
        else:
            bind_values = bind_type([id, value])
            bind_value_id = bind_type([id])
        insert_query = "INSERT INTO test (id, value) values( ?, ?)"
        select_query = "SELECT id, value FROM test WHERE id=?"
        insert = await session.create_prepared(insert_query)
        select = await session.create_prepared(select_query)
        await insert(bind_values)
        async for row in select(bind_value_id):
            assert dict(row) == expected_dict
        statement = select(bind_value_id)
        result = await session.execute(statement)
        assert len(result) == 1
        assert dict(result.first()) == expected_dict


class TestPythonicRow:
    @pytest.fixture(scope='class', autouse=True)
    def insert_query(self):
        return "INSERT INTO test (id, value_text) values( ?, ?)"

    @pytest.fixture(scope='class', autouse=True)
    def select_query(self):
        return "SELECT id, value_text FROM test WHERE id IN :ids"

    async def test_access_to_values(self, session, id_generation, insert_query, select_query):
        insert = await session.prepared_query(insert_query)
        select = await session.prepared_query(select_query)
        ids = [next(id_generation) for _ in range(10)]
        values = [f"v{k}" for k in ids]
        await asyncio.gather(*[insert((k, v)) for k, v in zip(ids, values)])
        result = await select([ids])
        for _ in range(2):
            for i, row in enumerate(result):
                assert row[0] == ids[i]
                assert row[1] == values[i]
                assert row[:-1] == (ids[i],)
                assert row[-1:] == (values[i],)
                assert row["id"] == ids[i]
                assert row["value_text"] == values[i]
                assert row.id == ids[i]
                assert row.value_text == values[i]
        i = 0
        async for row in select([ids]):
            assert row[0] == ids[i]
            assert row[1] == values[i]
            assert row[:-1] == (ids[i],)
            assert row[-1:] == (values[i],)
            assert row["id"] == ids[i]
            assert row["value_text"] == values[i]
            assert row.id == ids[i]
            assert row.value_text == values[i]
            i += 1
