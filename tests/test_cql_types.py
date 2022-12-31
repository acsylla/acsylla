from . import cql_types
from acsylla import create_statement

import pytest

pytestmark = pytest.mark.asyncio


class TestCQLTypes:
    @pytest.fixture(params=["set", "list", "tuple"], scope="class")
    async def set_list_tuple(self, request):
        return request.param

    @pytest.fixture(params=sorted(set(cql_types.native_types)), scope="class")
    async def data_type(self, request):
        return request.param

    def query(self, column, table, _id):
        return create_statement(f"SELECT {column} FROM test_{table} WHERE id={_id}")

    async def test_invalid_native(self, data_type, session, id_generation):
        query = cql_types.insert_query("native", data_type)
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        data = cql_types.native_types[data_type]
        column = f"value_{data_type}"
        for el in data["invalid"]:
            print(f"Bind INVALID value_{data_type} {el}")
            value, exception = el
            with pytest.raises(exception):
                statement.bind(1, value)
                statement.bind_by_name(column, value)
                statement.bind_list([1, value])
                statement.bind_dict({"id": 1, column: value})

    async def test_valid_native(self, data_type, session, id_generation):
        query = cql_types.insert_query("native", data_type)
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        data = cql_types.native_types[data_type]
        column = f"value_{data_type}"
        for el in data["valid"]:
            value, expected_value = el
            if isinstance(expected_value, tuple):
                expected_native_value, expected_value = expected_value
            else:
                expected_native_value = expected_value
            print(f"Bind VALID value_{data_type}: {value}")
            _id = next(id_generation)
            statement.bind(0, _id)
            statement.bind(1, value)
            await session.execute(statement)

            query = self.query(column, "native", _id)

            result = await session.execute(query, native_types=False)
            db_value = result.first().column_value(column)
            assert db_value == expected_value

            result = await session.execute(query, native_types=True)
            db_value = result.first().column_value(column)
            assert db_value == expected_native_value

    async def test_invalid_map(self, data_type, session, id_generation):
        # map doesn't support duration as key
        if data_type == "duration":
            return
        query = cql_types.insert_query("map", data_type)
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        data = cql_types.native_types[data_type]
        column = f"value_{data_type}"
        for el in data["invalid"]:
            print(f"Bind INVALID value_{data_type} {el}")
            value, exception = el
            dict_value = {value: value}
            list_value = [value, value]
            with pytest.raises(exception):
                statement.bind(1, dict_value)
                statement.bind(1, list_value)
                statement.bind_by_name(column, dict_value)
                statement.bind_by_name(column, list_value)

    async def test_valid_map(self, data_type, session, id_generation):
        # map doesn't support duration as key
        if data_type == "duration":
            return
        query = cql_types.insert_query("map", data_type)
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        data = cql_types.native_types[data_type]
        column = f"value_{data_type}"
        for el in data["valid"]:
            value, expected_value = el
            value = {value: value}
            if isinstance(expected_value, tuple):
                expected_native_value, expected_value = expected_value
            else:
                expected_native_value = expected_value
            expected_value = {expected_value: expected_value}
            expected_native_value = {expected_native_value: expected_native_value}
            print(f"Bind VALID value_{data_type}: {value}")
            _id = next(id_generation)
            statement.bind(0, _id)
            statement.bind(1, value)
            await session.execute(statement)

            query = self.query(column, "map", _id)

            result = await session.execute(query, native_types=False)
            db_value = result.first().column_value(column)
            assert db_value == expected_value

            result = await session.execute(query, native_types=True)
            db_value = result.first().column_value(column)
            assert db_value == expected_native_value

    async def test_invalid_udt(self, data_type, session, id_generation):
        query = cql_types.insert_query("udt", data_type)
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        data = cql_types.native_types[data_type]
        column = f"value_{data_type}"
        for el in data["invalid"]:
            value, exception = el
            with pytest.raises(exception):
                statement.bind(1, {column: value})
                statement.bind_by_name(column, {column: value})

    async def test_valid_udt(self, data_type, session, id_generation):
        query = cql_types.insert_query("udt", data_type)
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        data = cql_types.native_types[data_type]
        column = f"value_{data_type}"
        for el in data["valid"]:
            value, expected_value = el
            if isinstance(expected_value, tuple):
                expected_native_value, expected_value = expected_value
            else:
                expected_native_value = expected_value

            _id = next(id_generation)
            statement.bind(0, _id)
            statement.bind(1, {column: value})
            await session.execute(statement)

            query = self.query(column, "udt", _id)

            result = await session.execute(query, native_types=False)
            db_value = result.first().column_value(column)[column]
            assert db_value == expected_value

            result = await session.execute(query, native_types=True)
            db_value = result.first().column_value(column)[column]
            assert db_value == expected_native_value

    async def test_invalid_set_list_tuple(self, set_list_tuple, data_type, session, id_generation):
        # set doesn't support duration type
        if set_list_tuple == "set" and data_type == "duration":
            return
        query = cql_types.insert_query(set_list_tuple, data_type)
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        data = cql_types.native_types[data_type]
        column = f"value_{data_type}"
        for el in data["invalid"]:
            value, exception = el
            value = (value, value)
            with pytest.raises(exception):
                statement.bind(1, value)
                statement.bind_by_name(column, value)

    async def test_valid_set_list_tuple(self, set_list_tuple, data_type, session, id_generation):
        # set doesn't support duration type
        if set_list_tuple == "set" and data_type == "duration":
            return
        query = cql_types.insert_query(set_list_tuple, data_type)
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        data = cql_types.native_types[data_type]
        column = f"value_{data_type}"
        for el in data["valid"]:
            value, expected_value = el
            value = (value, value)
            if isinstance(expected_value, tuple):
                expected_native_value, expected_value = expected_value
            else:
                expected_native_value = expected_value
            expected_value = (expected_value, expected_value)
            expected_native_value = (expected_native_value, expected_native_value)
            if set_list_tuple == "list":
                expected_value = list(expected_value)
                expected_native_value = list(expected_native_value)
            if set_list_tuple == "set":
                expected_value = set(expected_value)
                expected_native_value = set(expected_native_value)
            _id = next(id_generation)
            statement.bind(0, _id)
            statement.bind(1, value)
            await session.execute(statement)

            query = self.query(column, set_list_tuple, _id)

            result = await session.execute(query, native_types=False)
            db_value = result.first().column_value(column)
            assert db_value == expected_value

            result = await session.execute(query, native_types=True)
            db_value = result.first().column_value(column)
            assert db_value == expected_native_value

    async def test_bind_all_values(self, session, id_generation):
        query = cql_types.insert_query("native")
        prepared = await session.create_prepared(query)
        statement_list = prepared.bind()
        statement_dict = prepared.bind()
        list_id = next(id_generation)
        list_values = [list_id]
        dict_id = next(id_generation)
        dict_values = {"id": dict_id}
        expected_values = {}
        for data_type in sorted(set(cql_types.native_types)):
            value, expected = cql_types.native_types[data_type]["valid"][0]
            list_values.append(value)
            column = f"value_{data_type}"
            dict_values[column] = value
            if isinstance(expected, tuple):
                expected_values[column] = expected[1]
            else:
                expected_values[column] = expected

        statement_list.bind_list(list_values)
        await session.execute(statement_list)
        result = await session.execute(create_statement(f"SELECT * FROM test_native WHERE id={list_id}"))
        for column, value in result.first().as_dict().items():
            if column == "id":
                continue
            assert value == expected_values[column]

        statement_dict.bind_dict(dict_values)
        await session.execute(statement_dict)
        result = await session.execute(create_statement(f"SELECT * FROM test_native WHERE id={dict_id}"))
        for column, value in result.first().as_dict().items():
            if column == "id":
                continue
            assert value == expected_values[column]

    async def test_bind_udt_values_as_list(self, session, id_generation):
        query = cql_types.insert_query("udt")
        prepared = await session.create_prepared(query)
        statement = prepared.bind()
        _id = next(id_generation)
        values = []
        expected_values = {}
        for data_type in sorted(set(cql_types.native_types)):
            value, expected = cql_types.native_types[data_type]["valid"][0]
            values.append(value)
            column = f"value_{data_type}"
            if isinstance(expected, tuple):
                expected_values[column] = expected[1]
            else:
                expected_values[column] = expected

        list_values = [_id] + [values for _ in values]
        statement.bind_list(list_values)
        await session.execute(statement)
        result = await session.execute(create_statement(f"SELECT * FROM test_udt WHERE id={_id}"))
        for column, value in result.first().as_dict().items():
            if column == "id":
                continue
            assert isinstance(value, dict)
            for k, v in value.items():
                if k == "value_udt_type":
                    continue
                assert v == expected_values[k]
