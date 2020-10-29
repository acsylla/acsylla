from acsylla import create_statement, types

import pytest

pytestmark = pytest.mark.asyncio


class TestRow:
    async def test_int(self, session, id_generation):
        id_ = next(id_generation)
        value = 100

        insert_statement = create_statement("INSERT INTO test (id, value_int) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_int FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_value("value_int") == value

    async def test_float(self, session, id_generation):
        id_ = next(id_generation)
        value = 100.0

        insert_statement = create_statement("INSERT INTO test (id, value_float) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_float FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_value("value_float") == value

    async def test_uuid(self, session, id_generation):
        id_ = next(id_generation)
        uuid = types.uuid("550e8400-e29b-41d4-a716-446655440000")

        insert_statement = create_statement("INSERT INTO test (id, value_uuid) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, uuid])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_uuid FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_value("value_uuid") == uuid

    async def test_bool(self, session, id_generation):
        id_ = next(id_generation)
        value = True

        insert_statement = create_statement("INSERT INTO test (id, value_bool) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_bool FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_value("value_bool") == value

    async def test_string(self, session, id_generation):
        id_ = next(id_generation)
        value = "acsylla"

        insert_statement = create_statement("INSERT INTO test (id, value_text) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_text FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_value("value_text") == value

    async def test_bytes(self, session, id_generation):
        id_ = next(id_generation)
        value = b"acsylla"

        insert_statement = create_statement("INSERT INTO test (id, value_blob) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_blob FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()

        assert row.column_value("value_blob") == value
