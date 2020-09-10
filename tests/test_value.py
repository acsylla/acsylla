from acsylla import create_statement

import pytest

pytestmark = pytest.mark.asyncio


class TestValue:
    async def test_int(self, session, id_generation):
        id_ = next(id_generation)
        value = 100

        insert_statement = create_statement("INSERT INTO test (id, value_int) values (?, ?)", parameters=2)
        insert_statement.bind_int(0, id_)
        insert_statement.bind_int(1, value)
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_int FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind_int(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_by_name("value_int").int() == value

    async def test_float(self, session, id_generation):
        id_ = next(id_generation)
        value = 100.0

        insert_statement = create_statement("INSERT INTO test (id, value_float) values (?, ?)", parameters=2)
        insert_statement.bind_int(0, id_)
        insert_statement.bind_float(1, value)
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_float FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind_int(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_by_name("value_float").float() == value

    async def test_uuid(self, session, id_generation):
        id_ = next(id_generation)
        value = "550e8400-e29b-41d4-a716-446655440000"

        insert_statement = create_statement("INSERT INTO test (id, value_uuid) values (?, ?)", parameters=2)
        insert_statement.bind_int(0, id_)
        insert_statement.bind_uuid(1, value)
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_uuid FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind_int(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_by_name("value_uuid").uuid() == value

    async def test_bool(self, session, id_generation):
        id_ = next(id_generation)
        value = True

        insert_statement = create_statement("INSERT INTO test (id, value_bool) values (?, ?)", parameters=2)
        insert_statement.bind_int(0, id_)
        insert_statement.bind_bool(1, value)
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_bool FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind_int(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_by_name("value_bool").bool() == value

    async def test_string(self, session, id_generation):
        id_ = next(id_generation)
        value = "acsylla"

        insert_statement = create_statement("INSERT INTO test (id, value_text) values (?, ?)", parameters=2)
        insert_statement.bind_int(0, id_)
        insert_statement.bind_string(1, value)
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_text FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind_int(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_by_name("value_text").string() == value

    async def test_bytes(self, session, id_generation):
        id_ = next(id_generation)
        value = b"acsylla"

        insert_statement = create_statement("INSERT INTO test (id, value_blob) values (?, ?)", parameters=2)
        insert_statement.bind_int(0, id_)
        insert_statement.bind_bytes(1, value)
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_blob FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind_int(0, id_)
        result = await session.execute(select_statement)
        row = result.first()

        assert row.column_by_name("value_blob").bytes() == value
