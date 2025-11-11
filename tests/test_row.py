from acsylla import create_statement
from datetime import date
from datetime import datetime
from datetime import time
from datetime import timedelta
from datetime import timezone
from decimal import Decimal
from ipaddress import IPv4Address
from ipaddress import IPv6Address

import pytest
import uuid

UTC = timezone.utc

pytestmark = pytest.mark.asyncio(loop_scope="class")


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
        value = 9223372036854775806

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
        value = 123.0

        insert_statement = create_statement("INSERT INTO test (id, value_float) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_float FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_value("value_float") == value

    async def test_float_as_string(self, session, id_generation):
        id_ = next(id_generation)
        value = "123.0"

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_float) values (?, ?)")
        statement = insert_statement.bind()
        statement.bind_list([id_, value])
        await session.execute(statement)

        select_statement = await session.create_prepared("SELECT value_float FROM test WHERE ( id = ? )")
        statement = select_statement.bind()
        statement.bind(0, id_)
        result = await session.execute(statement)

        row = result.first()

        assert row.column_value("value_float") == float(value)

    async def test_double(self, session, id_generation):
        id_ = next(id_generation)
        value = 3.0999999046325684

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

    async def test_double_as_string(self, session, id_generation):
        id_ = next(id_generation)
        value = "3.0999999046325684"

        insert_statement = await session.create_prepared("INSERT INTO test (id, value_double) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_double FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_double") == float(value)

    async def test_decimal(self, session, id_generation):
        id_ = next(id_generation)
        value = "3.141592653589793115997963468544185161590576171875"

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
        value = Decimal("3.141592653589793115997963468544185161590576171875")

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
        value = uuid.UUID("550e8400-e29b-41d4-a716-446655440000")

        insert_statement = create_statement("INSERT INTO test (id, value_uuid) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_uuid FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        row = result.first()

        assert row.column_value("value_uuid") == str(value)

    async def test_timeuuid(self, session, id_generation):
        id_ = next(id_generation)
        value = str(uuid.uuid1())

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

        value = "2a901afe-e8c4-11eb-9b07-acde48001122"
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)

        row = result.first()

        assert row.column_value("value_timeuuid") == value

    async def test_ascii(self, session, id_generation):
        id_ = next(id_generation)
        value = "ascii string"

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
        value = "unicode string"

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
        value = IPv4Address("127.0.0.1")
        insert_statement = create_statement("INSERT INTO test (id, value_inet) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)
        select_statement = create_statement("SELECT value_inet FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_inet") == "127.0.0.1"

    async def test_inet6(self, session, id_generation):
        id_ = next(id_generation)
        value = IPv6Address("::1")
        insert_statement = create_statement("INSERT INTO test (id, value_inet) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)
        select_statement = create_statement("SELECT value_inet FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_inet") == "::1"

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
        value = "0001-01-01"
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_date) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_date FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_date") == datetime.strptime("0001-01-01", "%Y-%m-%d").date()

    async def test_date_from_datetime(self, session, id_generation):
        id_ = next(id_generation)
        value = datetime.strptime("2021-07-20", "%Y-%m-%d")
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
        value = time.fromisoformat("16:34:56")
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
        value = "12:34:59.123456"
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_time) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_time FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_time") == time.fromisoformat(value)

    async def test_time_from_timestamp(self, session, id_generation):
        id_ = next(id_generation)
        value = 45299.123456
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_time) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_time FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_time") == datetime.fromtimestamp(value, tz=UTC).time()

    async def test_time_from_datetime(self, session, id_generation):
        id_ = next(id_generation)
        value = datetime.strptime("2021-07-20 12:24", "%Y-%m-%d %H:%M")
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
        value = datetime.fromisoformat("2022-12-09T18:19:49.322+00:00")
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
        value = "2021-07-21 15:24:31"
        expected_value = datetime.fromisoformat("2021-07-21 15:24:31+00:00")
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_timestamp) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_timestamp FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_timestamp") == expected_value

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
        assert row.column_value("value_timestamp") == datetime.fromtimestamp(value, tz=UTC)

    async def test_duration(self, session, id_generation):
        id_ = next(id_generation)
        value = timedelta(
            days=720, seconds=560, microseconds=3444, milliseconds=21324, minutes=123424, hours=23432, weeks=12340
        )
        insert_statement = create_statement("INSERT INTO test (id, value_duration) values (?, ?)", parameters=2)
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        select_statement = create_statement("SELECT value_duration FROM test WHERE ( id = ? )", parameters=1)
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)
        row = result.first()
        assert row.column_value("value_duration") == "88162d1h13m41s327ms444us"

    async def test_map(self, session, id_generation):
        id_ = next(id_generation)
        value = {"key": 123}
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_map_text_bigint) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_map_text_bigint FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_map_text_bigint") == value

    async def test_set(self, session, id_generation):
        id_ = next(id_generation)
        value = {"12", "123"}
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_set_text) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_set_text FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_set_text") == value

    async def test_list(self, session, id_generation):
        id_ = next(id_generation)
        value = ["test", "passed"]
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_list_text) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_list_text FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_list_text") == value

    async def test_tuple(self, session, id_generation):
        id_ = next(id_generation)
        value = ("test", 9223372036854775807)
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_tuple_text_bigint) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_tuple_text_bigint FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_tuple_text_bigint") == value

    async def test_udt(self, session, id_generation):
        id_ = next(id_generation)
        value = {
            "value_ascii": "John",
            "value_bigint": 9223372036854775807,
            "value_blob": b"blob",
            "value_boolean": True,
            "value_date": date.fromisoformat("2020-01-01"),
            "value_decimal": Decimal("3.141592653589793"),
            "value_double": 3.1415927410125732,
            "value_duration": "7d",
            "value_float": 3.141590118408203,
            "value_inet": "127.0.0.1",
            "value_int": -2147483648,
            "value_smallint": -32768,
            "value_text": "text",
            "value_time": time.fromisoformat("10:48:59"),
            "value_timestamp": datetime.fromisoformat("2021-07-21 15:24:31+00:00"),
            "value_timeuuid": str(uuid.uuid1()),
            "value_tinyint": -127,
            "value_varchar": "varchar value",
            "value_varint": b"varint",
            "value_map_text_bigint": {"text bigint": 9223372036854775807},
            "value_set_text": {"set", "text"},
            "value_list_text": ["list", "of", "text"],
            "value_tuple_text_bigint": ("tuple text and bigint", 9223372036854775807),
            "value_nested_udt": {"value_ascii": "John", "value_bigint": None},
        }
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_udt) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT value_udt FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("value_udt") == value

    async def test_list_of_udt(self, session, id_generation):
        id_ = next(id_generation)
        value = [{"value_ascii": "John", "value_bigint": None}, {"value_ascii": "John", "value_bigint": 123}]
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_list_udt) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT * FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("id") == id_

    async def test_set_of_udt(self, session, id_generation):
        id_ = next(id_generation)
        value = ({"value_ascii": "John", "value_bigint": None}, {"value_ascii": "John", "value_bigint": 123})
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_set_udt) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT * FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("id") == id_

    async def test_map_of_udt(self, session, id_generation):
        id_ = next(id_generation)
        value = {1: {"value_ascii": "John", "value_bigint": None}, 2: {"value_ascii": "John", "value_bigint": 123}}
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_map_udt) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT * FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("id") == id_

    async def test_tuple_of_udt(self, session, id_generation):
        id_ = next(id_generation)
        value = ({"value_ascii": "John", "value_bigint": None}, {"value_ascii": "John", "value_bigint": 123})
        insert_statement = await session.create_prepared("INSERT INTO test (id, value_tuple_udt) values (?, ?)")
        prepared = insert_statement.bind()
        prepared.bind_list([id_, value])
        await session.execute(prepared)

        select_statement = await session.create_prepared("SELECT * FROM test WHERE ( id = ? )")
        prepared = select_statement.bind()
        prepared.bind(0, id_)
        result = await session.execute(prepared)
        row = result.first()
        assert row.column_value("id") == id_
