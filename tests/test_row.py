import pytest

from uuid import UUID
from decimal import Decimal
from ipaddress import IPv4Address, IPv6Address
from datetime import date, datetime, time, timedelta

from acsylla import create_statement, types


pytestmark = pytest.mark.asyncio


class TestRow:

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

    async def test_tinyint(self, session, id_generation):
        id_ = next(id_generation)
        value = 127

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_tinyint) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_tinyint FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_tinyint") == value

    async def test_smallint(self, session, id_generation):
        id_ = next(id_generation)
        value = 32767

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_smallint) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_smallint FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_smallint") == value

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

    async def test_bigint(self, session, id_generation):
        id_ = next(id_generation)
        value = 9223372036854775807

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_bigint) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_bigint FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_bigint") == value

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

    async def test_double(self, session, id_generation):
        id_ = next(id_generation)
        value = 3.141592653589793

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_double) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_double FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_double") == value

    async def test_decimal(self, session, id_generation):
        id_ = next(id_generation)
        value = '3.141592653589793115997963468544185161590576171875'

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_decimal) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_decimal FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_decimal") == Decimal(value)

        id_ = next(id_generation)
        value = Decimal('3.141592653589793115997963468544185161590576171875')

        insert_statement = create_statement("INSERT INTO test (id, value_decimal) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_decimal FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_value("value_decimal") == value


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

        assert row.column_value("value_uuid") == UUID(uuid.uuid)

    async def test_timeuuid(self, session, id_generation):
        id_ = next(id_generation)
        import uuid
        value = uuid.uuid1()

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_timeuuid) values (?, ?)")
        select_statement = await session.create_prepared("SELECT value_timeuuid FROM test WHERE ( id = ? )")

        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_timeuuid") == value

        value = '2a901afe-e8c4-11eb-9b07-acde48001122'
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_timeuuid") == UUID(value)

    async def test_ascii(self, session, id_generation):
        id_ = next(id_generation)
        value = 'ascii string'

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_ascii) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_ascii FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_ascii") == value

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

    async def test_varchar(self, session, id_generation):
        id_ = next(id_generation)
        value = 'unicode string'

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_varchar) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_varchar FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_varchar") == value

    async def test_varint(self, session, id_generation):
        id_ = next(id_generation)
        value = b"acsylla"

        insert_statement = create_statement("INSERT INTO test (id, value_varint) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_varint FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()

        assert row.column_value("value_varint") == value

    async def test_inet4(self, session, id_generation):
        id_ = next(id_generation)
        value = IPv4Address('127.0.0.1')
        insert_statement = create_statement("INSERT INTO test (id, value_inet) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)
        select_statement = create_statement("SELECT value_inet FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_inet") == value

    async def test_inet6(self, session, id_generation):
        id_ = next(id_generation)
        value = IPv6Address('::1')
        insert_statement = create_statement("INSERT INTO test (id, value_inet) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)
        select_statement = create_statement("SELECT value_inet FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_inet") == value

    async def test_date(self, session, id_generation):
        id_ = next(id_generation)
        value = date.today()
        insert_statement = create_statement("INSERT INTO test (id, value_date) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_date FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_date") == value

    async def test_date_from_str(self, session, id_generation):
        id_ = next(id_generation)
        value = '2021-07-20'
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_date) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_date FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_date") == datetime.strptime('2021-07-20', "%Y-%m-%d").date()

    async def test_date_from_datetime(self, session, id_generation):
        id_ = next(id_generation)
        value = datetime.strptime('2021-07-20', "%Y-%m-%d")
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_date) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_date FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_date") == value.date()

    async def test_time(self, session, id_generation):
        id_ = next(id_generation)
        value = time.fromisoformat('16:34:56')
        insert_statement = create_statement("INSERT INTO test (id, value_time) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_time FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_time") == value

    async def test_time_from_str(self, session, id_generation):
        id_ = next(id_generation)
        value = '12:34:59'
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_time) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_time FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_time") == time.fromisoformat('12:34:59')

    async def test_time_from_datetime(self, session, id_generation):
        id_ = next(id_generation)
        value = datetime.strptime('2021-07-20 12:24', "%Y-%m-%d %H:%M")
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_time) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_time FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_time") == value.time()

    async def test_timestamp(self, session, id_generation):
        id_ = next(id_generation)
        value = datetime.fromisoformat('2021-07-21 15:24:31')
        insert_statement = create_statement("INSERT INTO test (id, value_timestamp) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_timestamp FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_timestamp") == value

    async def test_timestamp_from_str(self, session, id_generation):
        id_ = next(id_generation)
        value = '2021-07-21 15:24:31'
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_timestamp) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_timestamp FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_timestamp") == datetime.fromisoformat(value)

    async def test_timestamp_from_unixtime(self, session, id_generation):
        id_ = next(id_generation)
        value = 1626855981.809
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_timestamp) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_timestamp FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_timestamp") == datetime.utcfromtimestamp(value)

    async def test_duration(self, session, id_generation):
        id_ = next(id_generation)
        value = timedelta(days=720, seconds=560, microseconds=3444,
                          milliseconds=21324, minutes=123424,
                          hours=23432, weeks=12340)
        insert_statement = create_statement("INSERT INTO test (id, value_duration) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_duration FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_duration") == value

    async def test_map(self, session, id_generation):
        id_ = next(id_generation)
        value = {'key': 9223372036854775807}
        insert_statement = create_statement("INSERT INTO test (id, value_map_text_bigint) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_map_text_bigint FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_map_text_bigint") == value
