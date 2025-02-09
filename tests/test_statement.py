from acsylla import Consistency
from acsylla import create_statement
from acsylla import errors
from decimal import Decimal
from ipaddress import IPv4Address
from ipaddress import IPv6Address

import datetime
import pytest
import time
import uuid


statement_str = """
    INSERT INTO test (
            id,
            value,
            value_int,
            value_float,
            value_bool,
            value_text,
            value_blob,
            value_uuid,
            value_decimal,
            value_inet,
            value_date,
            value_time,
            value_timestamp,
            value_duration,
            value_map_text_bigint,
            value_set_text,
            value_list_text,
            value_tuple_text_bigint,
            value_udt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
"""


class TestStatement:

    OUT_OF_BAND_PARAMETER = 100

    @pytest.fixture(scope="class", params=["none_prepared", "prepared"], autouse=True)
    async def statement(self, request, session):
        if request.param == "none_prepared":
            statement_ = create_statement(statement_str, parameters=19)
        elif request.param == "prepared":
            prepared = await session.create_prepared(statement_str)
            statement_ = prepared.bind()
        else:
            raise ValueError()

        return statement_

    def test_create_with_timeout(self):
        statement = create_statement("INSERT INTO test (id) values (1)", timeout=1.0)
        assert statement is not None
        statement.set_timeout(0.01)

    async def test_create_with_execution_profile(self):
        statement = create_statement("INSERT INTO test (id) values (1)", execution_profile="")
        statement.set_execution_profile("")
        assert statement is not None

    async def test_add_key_index(self):
        statement = create_statement("SELECT id, value FROM test WHERE id=?", 1)
        statement.add_key_index(0)

    async def test_reset_parameters(self):
        statement = create_statement("INSERT INTO test (id, values) VALUES (?, ?)", 2)
        statement.bind(0, 1)
        statement.bind(1, 1)
        statement.reset_parameters(2)
        statement.bind_list([1, 2])

    async def test_set_timestamp(self, statement):
        statement.set_timestamp(time.time())

    async def test_set_is_idempotent(self, statement):
        statement.set_is_idempotent(True)
        statement.set_is_idempotent(False)

    async def test_set_retry_policy(self, statement):
        statement.set_retry_policy("default")
        statement.set_retry_policy("fallthrough")
        statement.set_retry_policy("default", retry_policy_logging=True)
        statement.set_retry_policy("fallthrough", retry_policy_logging=True)
        statement.set_retry_policy(None)

    async def test_set_tracing(self, statement):
        statement.set_tracing(True)
        statement.set_tracing(False)
        statement.set_tracing(None)

    async def test_set_host(self, statement):
        statement.set_host("127.0.0.1")
        statement.set_host("127.0.0.1", port=123)
        statement.set_host(None)

    async def test_set_execute_as(self, statement):
        statement.set_execute_as("cassandra")

    @pytest.mark.parametrize(
        "consistency",
        [
            Consistency.ANY,
            Consistency.ONE,
            Consistency.TWO,
            Consistency.THREE,
            Consistency.QUORUM,
            Consistency.ALL,
            Consistency.LOCAL_QUORUM,
            Consistency.EACH_QUORUM,
            Consistency.SERIAL,
            Consistency.LOCAL_SERIAL,
            Consistency.LOCAL_ONE,
        ],
    )
    async def test_create_with_consistency(self, consistency):
        statement = create_statement("INSERT INTO test (id) values (1)", consistency=consistency)
        assert statement is not None
        statement.set_consistency(consistency)

    @pytest.mark.parametrize(
        "serial_consistency",
        [Consistency.SERIAL, Consistency.LOCAL_SERIAL],
    )
    async def test_create_with_serial_consistency(self, serial_consistency):
        statement = create_statement("INSERT INTO test (id) values (1)", serial_consistency=serial_consistency)
        assert statement is not None
        statement.set_serial_consistency(serial_consistency)

    def test_bind_list(self, statement):
        statement.bind_list(
            [1, None, 2, 10.0, True, "acsylla", b"acsylla", uuid.UUID("550e8400-e29b-41d4-a716-446655440000")]
        )

    def test_bind_null(self, statement):
        statement.bind(1, None)

    def test_bind_null_invalid_index(self, statement):
        with pytest.raises(errors.CassErrorLibIndexOutOfBounds):
            statement.bind(TestStatement.OUT_OF_BAND_PARAMETER, None)

    def test_bind_int(self, statement):
        statement.bind(2, 10)

    def test_bind_int_invalid_index(self, statement):
        with pytest.raises(errors.CassErrorLibIndexOutOfBounds):
            statement.bind(TestStatement.OUT_OF_BAND_PARAMETER, 10)

    def test_bind_float(self, statement):
        statement.bind(3, 10.0)

    def test_bind_float_invalid_index(self, statement):
        with pytest.raises(errors.CassErrorLibIndexOutOfBounds):
            statement.bind(TestStatement.OUT_OF_BAND_PARAMETER, 10.0)

    def test_bind_bool(self, statement):
        statement.bind(4, True)

    def test_bind_bool_invalid_index(self, statement):
        with pytest.raises(errors.CassErrorLibIndexOutOfBounds):
            statement.bind(TestStatement.OUT_OF_BAND_PARAMETER, True)

    def test_bind_string(self, statement):
        statement.bind(5, "acsylla")

    def test_bind_string_invalid_index(self, statement):
        with pytest.raises(errors.CassErrorLibIndexOutOfBounds):
            statement.bind(TestStatement.OUT_OF_BAND_PARAMETER, "acsylla")

    def test_test_bind_uuidbind_bytes(self, statement):
        statement.bind(6, b"acsylla")

    def test_bind_bytes_invalid_index(self, statement):
        with pytest.raises(errors.CassErrorLibIndexOutOfBounds):
            statement.bind(TestStatement.OUT_OF_BAND_PARAMETER, b"acsylla")

    def test_bind_uuid(self, statement):
        statement.bind(7, "550e8400-e29b-41d4-a716-446655440000")
        statement.bind(7, uuid.UUID("550e8400-e29b-41d4-a716-446655440000"))

    def test_bind_uuid_invalid_index(self, statement):
        with pytest.raises(errors.CassErrorLibIndexOutOfBounds):
            statement.bind(TestStatement.OUT_OF_BAND_PARAMETER, uuid.UUID("550e8400-e29b-41d4-a716-446655440000"))

    def test_bind_decimal(self, statement):
        value = Decimal("3.141592653589793115997963468544185161590576171875")
        statement.bind(8, value)

    def test_bind_inet(self, statement):
        value = IPv4Address("127.0.0.1")
        statement.bind(9, value)
        value = IPv6Address("::1")
        statement.bind(9, value)

    def test_bind_date(self, statement):
        statement.bind(10, datetime.date.today())

    def test_bind_time(self, statement):
        statement.bind(11, datetime.time.fromisoformat("15:24:31"))

    def test_bind_timestamp(self, statement):
        statement.bind(12, datetime.datetime.now())

    def test_bind_duration(self, statement):
        value = datetime.timedelta(
            days=720, seconds=560, microseconds=3444, milliseconds=21324, minutes=123424, hours=23432, weeks=12340
        )
        statement.bind(13, value)


class TestStatementOnlyPrepared:
    """Special tests for testing some methods that are only allowed for statements
    that were created by using prepared statements."""

    @pytest.fixture(scope='class', autouse=True)
    async def statement(self, session):
        prepared = await session.create_prepared(statement_str)
        statement_ = prepared.bind()
        return statement_

    def test_bind_dict(self, statement):
        statement.bind_dict(
            {
                "id": 1,
                "value": None,
                "value_int": 2,
                "value_float": 10.0,
                "value_bool": True,
                "value_text": "acsylla",
                "value_blob": b"acsylla",
                "value_uuid": uuid.UUID("550e8400-e29b-41d4-a716-446655440000"),
            }
        )
        statement.bind_dict(
            {
                "id": 1,
                "value": None,
                "value_int": 2,
                "value_float": 10.0,
                "value_bool": True,
                "value_text": "acsylla",
                "value_blob": b"acsylla",
                "value_uuid": "550e8400-e29b-41d4-a716-446655440000",
            }
        )
        statement.bind_dict(
            {
                "id": 1,
                "value": None,
                "value_int": 2,
                "value_float": 10.0,
                "value_bool": True,
                "value_text": "acsylla",
                "value_blob": b"acsylla",
                "value_uuid": uuid.UUID("550e8400-e29b-41d4-a716-446655440000"),
            }
        )

    def test_bind_null_by_name(self, statement):
        statement.bind_by_name("value", None)

    def test_bind_null_by_name_invalid_name(self, statement):
        with pytest.raises(errors.CassErrorLibNameDoesNotExist):
            statement.bind_by_name("invalid_field", None)

    def test_bind_int_by_name(self, statement):
        statement.bind_by_name("value_int", 10)

    def test_bind_int_by_name_value_error(self, statement):
        with pytest.raises(OverflowError):
            statement.bind_by_name("value_int", 2147483649)
        with pytest.raises(OverflowError):
            statement.bind_by_name("value_int", -2147483649)
        with pytest.raises(ValueError):
            statement.bind_by_name("value_int", "bad_value")

    def test_bind_int_by_name_invalid_name(self, statement):
        with pytest.raises(errors.CassErrorLibNameDoesNotExist):
            statement.bind_by_name("invalid_field", 10)

    def test_bind_uuid_by_name(self, statement):
        statement.bind_by_name("value_uuid", "550e8400-e29b-41d4-a716-446655440000")
        statement.bind_by_name("value_uuid", uuid.UUID("550e8400-e29b-41d4-a716-446655440000"))

    def test_bind_uuid_by_name_invalid_name(self, statement):
        with pytest.raises(errors.CassErrorLibNameDoesNotExist):
            statement.bind_by_name("invalid_field", uuid.UUID("550e8400-e29b-41d4-a716-446655440000"))

    def test_bind_float_by_name(self, statement):
        statement.bind_by_name("value_float", 10.0)

    def test_bind_float_by_name_invalid_name(self, statement):
        with pytest.raises(errors.CassErrorLibNameDoesNotExist):
            statement.bind_by_name("invalid_field", 10.0)

    def test_bind_bool_by_name(self, statement):
        statement.bind_by_name("value_bool", True)

    def test_bind_bool_by_name_invalid_name(self, statement):
        with pytest.raises(errors.CassErrorLibNameDoesNotExist):
            statement.bind_by_name("invalid_field", True)

    def test_bind_string_by_name(self, statement):
        statement.bind_by_name("value_text", "acsylla")

    def test_bind_string_by_name_invalid_name(self, statement):
        with pytest.raises(errors.CassErrorLibNameDoesNotExist):
            statement.bind_by_name("invalid_field", "acsylla")

    def test_bind_bytes_by_name(self, statement):
        statement.bind_by_name("value_blob", b"acsylla")

    def test_bind_bytes_by_name_invalid_name(self, statement):
        with pytest.raises(errors.CassErrorLibNameDoesNotExist):
            statement.bind_by_name("invalid_field", b"acsylla")

    def test_bind_decimal_by_name(self, statement):
        value = Decimal("3.141592653589793115997963468544185161590576171875")
        statement.bind_by_name("value_decimal", value)
        value = "3.141592653589793115997963468544185161590576171875"
        statement.bind_by_name("value_decimal", value)

    def test_bind_inet_by_name(self, statement):
        value = IPv4Address("127.0.0.1")
        statement.bind_by_name("value_inet", value)
        value = IPv6Address("::1")
        statement.bind_by_name("value_inet", value)
        value = "127.0.0.1"
        statement.bind_by_name("value_inet", value)
        value = "::1"
        statement.bind_by_name("value_inet", value)

    def test_bind_date_by_name(self, statement):
        statement.bind_by_name("value_date", datetime.date.today())
        statement.bind_by_name("value_date", datetime.datetime.now())
        statement.bind_by_name("value_date", "2011-07-20")
        statement.bind_by_name("value_date", 1626728400)

    def test_bind_time_by_name(self, statement):
        statement.bind_by_name("value_time", datetime.time.fromisoformat("15:24:31"))

    def test_bind_timestamp_by_name(self, statement):
        statement.bind_by_name("value_timestamp", datetime.datetime.fromisoformat("2021-07-21 15:24:31"))
        statement.bind_by_name("value_timestamp", "2021-07-21 15:24:31")
        statement.bind_by_name("value_timestamp", 1626870271.32)

    def test_bind_duration_by_name(self, statement):
        value = datetime.timedelta(
            days=720, seconds=560, microseconds=3444, milliseconds=21324, minutes=123424, hours=23432, weeks=12340
        )
        statement.bind_by_name("value_duration", value)

    def test_bind_map_text_bigint(self, statement):
        value = {"key": 9223372036854775807}
        statement.bind(14, value)

    def test_bind_map_text_bigint_by_name(self, statement):
        value = {"key": 9223372036854775807}
        statement.bind_by_name("value_map_text_bigint", value)

    def test_bind_set_text(self, statement):
        value = {"test", "passed"}
        statement.bind(15, value)

    def test_bind_set_text_by_name(self, statement):
        value = {"test", "passed"}
        statement.bind_by_name("value_set_text", value)

    def test_bind_list_text(self, statement):
        value = ["test", "passed"]
        statement.bind(16, value)

    def test_bind_list_text_by_name(self, statement):
        value = ["test", "passed"]
        statement.bind_by_name("value_list_text", value)

    def test_bind_tuple_text_bigint(self, statement):
        value = ("test", 9223372036854775807)
        statement.bind(17, value)

    def test_bind_tuple_text_bigint_by_name(self, statement):
        value = ("key", 9223372036854775807)
        statement.bind_by_name("value_tuple_text_bigint", value)

    def test_bind_udt(self, statement):
        value = {"value_ascii": "John", "value_bigint": 9223372036854775807}
        statement.bind(18, value)

    def test_bind_udt_by_name(self, statement):
        value = {"value_ascii": "John", "value_bigint": 9223372036854775807}
        statement.bind_by_name("value_udt", value)
