"""CQL values checked against the server, not against acsylla itself.

Read: every value is written as a CQL literal, so the server parses it and acsylla only reads it.
Write: a value bound by acsylla must give the server the same bytes as the CQL literal of the case, compared with
typeAsBlob() for a native type and with toJson() for the others. The values acsylla returns, with and without
native_types, are bound back the same way.

The cases describe acsylla 2.0. A case that is not done yet is marked xfail(strict=True) with the stage of the plan that
does it, so the stage that makes it pass has to remove the mark.
"""

from acsylla import create_cluster
from acsylla import create_statement
from acsylla import errors
from dataclasses import dataclass
from dataclasses import field
from datetime import date
from datetime import datetime
from datetime import time
from datetime import timedelta
from datetime import timezone
from decimal import Decimal
from ipaddress import IPv4Address
from ipaddress import IPv6Address
from types import FunctionType
from uuid import UUID

import acsylla
import math
import os
import pytest
import re

pytestmark = pytest.mark.asyncio(loop_scope="class")

UTC = timezone.utc

DECIMAL = "stage 1: decimal"
VARINT = "stage 2: varint"
DATETIME = "stage 3: date, time, timestamp"
UUIDS = "stage 4: uuid"
INET = "stage 5: inet"
UUIDS_INET = "stages 4, 5: uuid, inet"
DURATION = "stage 6: Duration"
VECTOR = "stage 7: vector"
UNHASHABLE = "stage 8: unhashable set elements and map keys"
ROW = "stage 9: Row"
NATIVE = "stage 10: native_types"

NATIVE_TYPES = {
    "ascii",
    "bigint",
    "blob",
    "boolean",
    "counter",
    "date",
    "decimal",
    "double",
    "duration",
    "float",
    "inet",
    "int",
    "smallint",
    "text",
    "time",
    "timestamp",
    "timeuuid",
    "tinyint",
    "uuid",
    "varchar",
    "varint",
}


@dataclass(frozen=True)
class Raises:
    """Reading the value raises `exception` with a message that matches `match`."""

    exception: type
    match: str


@dataclass(frozen=True, eq=False)
class Case:
    """A value of `cql_type` written as the CQL `literal`, acsylla reads it as `value` and with native_types as
    `native`, and binding them must give the server the same value."""

    id: str
    cql_type: str
    literal: str
    value: object
    native: object
    # What is not done yet: "read", "native", "write" or "write native" -> the stage that does it
    todo: dict = field(default_factory=dict)
    # An empty value is read as None, binding None writes null instead
    round_trip: bool = True
    # False when the value read without native_types loses a part of it, nanoseconds of a time
    lossless: bool = True


@dataclass(frozen=True, eq=False)
class WriteCase:
    """Binding `value` to a column of `cql_type` must give the server the same value as the CQL `literal`."""

    id: str
    cql_type: str
    value: object
    literal: str
    todo: str = None
    needs: str = None


def duration(months, days, nanoseconds):
    # acsylla.Duration does not exist yet, the value is made when the test runs
    return lambda: acsylla.Duration(months, days, nanoseconds)


def relativedelta(**kwargs):
    return lambda: pytest.importorskip("dateutil.relativedelta").relativedelta(**kwargs)


UUID_1 = "550e8400-e29b-41d4-a716-446655440000"
TIMEUUID_1 = "3cd1a00b-7bee-11ed-aff2-510dcc4598b0"
ADDR = "CREATE TYPE IF NOT EXISTS addr (street text, num int)"

CASES = [
    Case("ascii", "ascii", "'abc'", "abc", "abc"),
    Case("ascii-empty", "ascii", "''", "", ""),
    Case("text", "text", "'привет'", "привет", "привет"),
    Case("varchar", "varchar", "'v'", "v", "v"),
    Case("boolean", "boolean", "true", True, True),
    Case("tinyint", "tinyint", "-128", -128, -128),
    Case("smallint", "smallint", "32767", 32767, 32767),
    Case("int", "int", "-2147483648", -2147483648, -2147483648),
    Case("bigint", "bigint", "9223372036854775807", 9223372036854775807, 9223372036854775807),
    Case("float", "float", "3.14", 3.140000104904175, 3.140000104904175),
    Case("float-nan", "float", "NaN", math.nan, math.nan),
    Case("float-infinity", "float", "-Infinity", -math.inf, -math.inf),
    Case("double", "double", "98.76", 98.76, 98.76),
    Case("double-nan", "double", "NaN", math.nan, math.nan),
    Case("blob", "blob", "0x0102ff", b"\x01\x02\xff", b"\x01\x02\xff"),
    Case("blob-empty", "blob", "0x", b"", b""),
    Case(
        "varint",
        "varint",
        "123456789012345678901234567890",
        123456789012345678901234567890,
        123456789012345678901234567890,
        todo={"read": VARINT, "native": VARINT, "write": VARINT, "write native": VARINT},
    ),
    Case(
        "varint-negative",
        "varint",
        "-123456789012345678901234567890",
        -123456789012345678901234567890,
        -123456789012345678901234567890,
        todo={"read": VARINT, "native": VARINT, "write": VARINT, "write native": VARINT},
    ),
    Case(
        "varint-minus-one",
        "varint",
        "-1",
        -1,
        -1,
        todo={"read": VARINT, "native": VARINT, "write": VARINT, "write native": VARINT},
    ),
    Case(
        "varint-zero",
        "varint",
        "0",
        0,
        0,
        todo={"read": VARINT, "native": VARINT, "write": VARINT, "write native": VARINT},
    ),
    Case(
        "decimal",
        "decimal",
        "1234.5678",
        Decimal("1234.5678"),
        "1234.5678",
        todo={"read": DECIMAL, "native": DECIMAL, "write": DECIMAL, "write native": DECIMAL},
    ),
    Case(
        "decimal-negative",
        "decimal",
        "-0.000001",
        Decimal("-0.000001"),
        "-0.000001",
        todo={"read": DECIMAL, "native": DECIMAL, "write": DECIMAL, "write native": DECIMAL},
    ),
    Case(
        "decimal-negative-scale",
        "decimal",
        "1E+10",
        Decimal("1E+10"),
        "1E+10",
        todo={"read": DECIMAL, "native": DECIMAL, "write": DECIMAL, "write native": DECIMAL},
    ),
    Case(
        "decimal-precision",
        "decimal",
        "3.141592653589793115997963468544185161590576171875",
        Decimal("3.141592653589793115997963468544185161590576171875"),
        "3.141592653589793115997963468544185161590576171875",
        todo={"read": DECIMAL, "native": DECIMAL, "write": DECIMAL, "write native": DECIMAL},
    ),
    Case(
        "decimal-zero",
        "decimal",
        "0",
        Decimal("0"),
        "0",
        todo={"read": DECIMAL, "native": DECIMAL, "write": DECIMAL, "write native": DECIMAL},
    ),
    Case("uuid", "uuid", UUID_1, UUID(UUID_1), UUID_1, todo={"read": UUIDS}),
    Case("timeuuid", "timeuuid", TIMEUUID_1, UUID(TIMEUUID_1), TIMEUUID_1, todo={"read": UUIDS}),
    Case("inet", "inet", "'192.168.1.100'", IPv4Address("192.168.1.100"), "192.168.1.100", todo={"read": INET}),
    Case("inet-ipv6", "inet", "'::1'", IPv6Address("::1"), "::1", todo={"read": INET}),
    Case(
        "inet-ipv6-long",
        "inet",
        "'2001:db8::ff00:42:8329'",
        IPv6Address("2001:db8::ff00:42:8329"),
        "2001:db8::ff00:42:8329",
        todo={"read": INET},
    ),
    Case("date", "date", "'2024-06-15'", date(2024, 6, 15), "2024-06-15"),
    Case("date-before-epoch", "date", "'1969-12-31'", date(1969, 12, 31), "1969-12-31"),
    Case("date-first-python", "date", "'0001-01-01'", date(1, 1, 1), "0001-01-01"),
    Case("date-last-python", "date", "'9999-12-31'", date(9999, 12, 31), "9999-12-31"),
    # Cassandra takes a date out of 1..9999 only as 2^31 + days since 1970-01-01
    Case(
        "date-year-zero",
        "date",
        "2146764120",  # 0000-01-01
        Raises(ValueError, "value_date"),
        "0000-01-01",
        todo={"read": DATETIME, "native": DATETIME},
    ),
    Case(
        "date-before-year-zero",
        "date",
        "2146764119",  # -0001-12-31
        Raises(ValueError, "value_date"),
        "-0001-12-31",
        todo={"read": DATETIME, "native": DATETIME, "write native": DATETIME},
    ),
    Case(
        "date-first-cql",
        "date",
        "0",  # -5877641-06-23
        Raises(ValueError, "value_date"),
        "-5877641-06-23",
        todo={"read": DATETIME, "native": DATETIME, "write native": DATETIME},
    ),
    Case(
        "date-after-python",
        "date",
        "2150416545",  # 10000-01-01
        Raises(ValueError, "value_date"),
        "10000-01-01",
        todo={"read": DATETIME, "write native": DATETIME},
    ),
    Case(
        "date-last-cql",
        "date",
        "4294967295",  # 5881580-07-11
        Raises(ValueError, "value_date"),
        "5881580-07-11",
        todo={"read": DATETIME, "write native": DATETIME},
    ),
    Case("time", "time", "'12:34:56.123456789'", time(12, 34, 56, 123456), "12:34:56.123456789", lossless=False),
    Case("time-midnight", "time", "'00:00:00'", time(0, 0), "00:00:00.000000000"),
    Case("time-last", "time", "'23:59:59.999999999'", time(23, 59, 59, 999999), "23:59:59.999999999", lossless=False),
    Case(
        "timestamp",
        "timestamp",
        "'2024-06-15 12:30:00.123+0000'",
        datetime(2024, 6, 15, 12, 30, 0, 123000, tzinfo=UTC),
        "2024-06-15 12:30:00.123Z",
    ),
    Case("timestamp-epoch", "timestamp", "0", datetime(1970, 1, 1, tzinfo=UTC), "1970-01-01 00:00:00.000Z"),
    Case(
        "timestamp-before-epoch",
        "timestamp",
        "-1",
        datetime(1969, 12, 31, 23, 59, 59, 999000, tzinfo=UTC),
        "1969-12-31 23:59:59.999Z",
    ),
    Case(
        "timestamp-first-python",
        "timestamp",
        "-62135596800000",
        datetime(1, 1, 1, tzinfo=UTC),
        "0001-01-01 00:00:00.000Z",
    ),
    Case(
        "timestamp-last-python",
        "timestamp",
        "253402300799999",
        datetime(9999, 12, 31, 23, 59, 59, 999000, tzinfo=UTC),
        "9999-12-31 23:59:59.999Z",
        # Read through a float, it gives .998
        todo={"read": DATETIME, "native": DATETIME},
    ),
    Case(
        "timestamp-before-python",
        "timestamp",
        "-62135596800001",
        Raises(ValueError, "value_timestamp"),
        "0000-12-31 23:59:59.999Z",
        todo={"read": DATETIME, "native": DATETIME},
    ),
    Case(
        "timestamp-after-python",
        "timestamp",
        "253402300800000",
        Raises(ValueError, "value_timestamp"),
        "10000-01-01 00:00:00.000Z",
        todo={"read": DATETIME, "native": DATETIME, "write native": DATETIME},
    ),
    Case(
        "duration",
        "duration",
        "1y2mo3d4h5m6s7ms8us9ns",
        duration(14, 3, 14706007008009),
        "1y2mo3d4h5m6s7ms8us9ns",
        todo={"read": DURATION, "native": NATIVE, "write": DURATION},
    ),
    Case(
        "duration-negative",
        "duration",
        "-1d",
        duration(0, -1, 0),
        "-1d",
        todo={"read": DURATION, "native": NATIVE, "write": DURATION},
    ),
    Case(
        "duration-hours",
        "duration",
        "25h",
        duration(0, 0, 90000000000000),
        "25h",
        todo={"read": DURATION, "native": NATIVE, "write": DURATION},
    ),
    Case(
        "duration-zero",
        "duration",
        "0s",
        duration(0, 0, 0),
        "0s",
        todo={"read": DURATION, "native": NATIVE, "write": DURATION},
    ),
    Case("list", "list<int>", "[3, 1, 2]", [3, 1, 2], [3, 1, 2]),
    Case("set", "set<int>", "{3, 1, 2}", {1, 2, 3}, {1, 2, 3}),
    Case("map", "map<text, int>", "{'b': 2, 'a': 1}", {"a": 1, "b": 2}, {"a": 1, "b": 2}),
    Case("tuple", "tuple<int, text>", "(1, 'x')", (1, "x"), (1, "x")),
    Case(
        "udt",
        "frozen<addr>",
        "{street: 'Main', num: 5}",
        {"street": "Main", "num": 5},
        {"street": "Main", "num": 5},
    ),
    Case("list-uuid", "list<uuid>", f"[{UUID_1}]", [UUID(UUID_1)], [UUID_1], todo={"read": UUIDS}),
    Case(
        "map-timeuuid-inet",
        "map<timeuuid, inet>",
        f"{{{TIMEUUID_1}: '10.0.0.1'}}",
        {UUID(TIMEUUID_1): IPv4Address("10.0.0.1")},
        {TIMEUUID_1: "10.0.0.1"},
        todo={"read": UUIDS_INET},
    ),
    Case(
        "list-varint",
        "list<varint>",
        "[1, -1, 123456789012345678901234567890]",
        [1, -1, 123456789012345678901234567890],
        [1, -1, 123456789012345678901234567890],
        todo={"read": VARINT, "native": VARINT, "write": VARINT, "write native": VARINT},
    ),
    Case(
        "set-decimal",
        "set<decimal>",
        "{1.5, 2.25}",
        {Decimal("1.5"), Decimal("2.25")},
        {"1.5", "2.25"},
        todo={"read": DECIMAL, "native": DECIMAL, "write": DECIMAL, "write native": DECIMAL},
    ),
    Case(
        "list-duration",
        "list<duration>",
        "[1d, 2h]",
        [duration(0, 1, 0), duration(0, 0, 7200000000000)],
        ["1d", "2h"],
        todo={"read": DURATION, "native": NATIVE, "write": DURATION},
    ),
    Case("list-list", "list<frozen<list<int>>>", "[[1, 2], [3]]", [[1, 2], [3]], [[1, 2], [3]]),
    Case("map-set", "map<int, frozen<set<int>>>", "{1: {2, 3}}", {1: {2, 3}}, {1: {2, 3}}),
    Case(
        "tuple-nested",
        "tuple<int, frozen<list<int>>, frozen<addr>>",
        "(1, [2, 3], {street: 'c', num: 3})",
        (1, [2, 3], {"street": "c", "num": 3}),
        (1, [2, 3], {"street": "c", "num": 3}),
    ),
    Case("set-tuple", "set<frozen<tuple<int, text>>>", "{(1, 'x')}", {(1, "x")}, {(1, "x")}),
    Case(
        "set-list",
        "set<frozen<list<int>>>",
        "{[1, 2], [3]}",
        [[1, 2], [3]],
        [[1, 2], [3]],
        todo={"read": UNHASHABLE, "native": UNHASHABLE},
    ),
    Case(
        "set-set",
        "set<frozen<set<int>>>",
        "{{1, 2}}",
        [{1, 2}],
        [{1, 2}],
        todo={"read": UNHASHABLE, "native": UNHASHABLE},
    ),
    Case(
        "set-map",
        "set<frozen<map<int, int>>>",
        "{{1: 2}}",
        [{1: 2}],
        [{1: 2}],
        todo={"read": UNHASHABLE, "native": UNHASHABLE},
    ),
    Case(
        "set-udt",
        "set<frozen<addr>>",
        "{{street: 'a', num: 1}}",
        [{"street": "a", "num": 1}],
        [{"street": "a", "num": 1}],
        todo={"read": UNHASHABLE, "native": UNHASHABLE},
    ),
    Case(
        "set-tuple-list",
        "set<frozen<tuple<int, frozen<list<int>>>>>",
        "{(1, [2])}",
        [(1, [2])],
        [(1, [2])],
        todo={"read": UNHASHABLE, "native": UNHASHABLE},
    ),
    Case(
        "map-list-key",
        "map<frozen<list<int>>, int>",
        "{[1, 2]: 10}",
        [([1, 2], 10)],
        [([1, 2], 10)],
        todo={"read": UNHASHABLE, "native": UNHASHABLE},
    ),
    Case(
        "map-udt-key",
        "map<frozen<addr>, int>",
        "{{street: 'b', num: 2}: 20}",
        [({"street": "b", "num": 2}, 20)],
        [({"street": "b", "num": 2}, 20)],
        todo={"read": UNHASHABLE, "native": UNHASHABLE},
    ),
    Case(
        "vector-float",
        "vector<float, 3>",
        "[1.5, 2.5, 3.5]",
        [1.5, 2.5, 3.5],
        [1.5, 2.5, 3.5],
        todo={"read": VECTOR, "native": VECTOR, "write": VECTOR, "write native": VECTOR},
    ),
    Case(
        "vector-int",
        "vector<int, 2>",
        "[1, -2]",
        [1, -2],
        [1, -2],
        todo={"read": VECTOR, "native": VECTOR, "write": VECTOR, "write native": VECTOR},
    ),
    Case(
        "vector-text",
        "vector<text, 2>",
        "['a', 'bc']",
        ["a", "bc"],
        ["a", "bc"],
        todo={"read": VECTOR, "native": VECTOR, "write": VECTOR, "write native": VECTOR},
    ),
]
# Empty values: 0 bytes, not null
CASES += [
    Case(f"{cql_type}-empty", cql_type, f"blobAs{cql_type}(0x)", None, None, round_trip=False)
    for cql_type in (
        "int",
        "bigint",
        "smallint",
        "tinyint",
        "boolean",
        "float",
        "double",
        "decimal",
        "uuid",
        "timeuuid",
        "inet",
        "date",
        "time",
        "timestamp",
    )
]
CASES += [
    Case(
        "varint-empty",
        "varint",
        "blobAsVarint(0x)",
        None,
        None,
        todo={"read": VARINT, "native": VARINT},
        round_trip=False,
    ),
]
CASES += [
    Case(f"{cql_type}-null", cql_type, "null", None, None)
    for cql_type in (
        "int",
        "varint",
        "decimal",
        "uuid",
        "date",
        "timestamp",
        "duration",
        "list<int>",
        "set<int>",
        "map<text, int>",
        "tuple<int, text>",
        "frozen<addr>",
        "vector<float, 3>",
    )
]

WRITE_CASES = [
    WriteCase("decimal-str", "decimal", "1234.5678", "1234.5678", DECIMAL),
    WriteCase("decimal-str-exponent", "decimal", "1E+10", "1E+10", DECIMAL),
    WriteCase("decimal-int", "decimal", 5, "5", DECIMAL),
    WriteCase("decimal-float", "decimal", 3.14, "3.14", DECIMAL),
    # bytes are the two's complement of the number, as before
    WriteCase("varint-bytes", "varint", b"\x7b", "123"),
    WriteCase("varint-str", "varint", "123", "123", VARINT),
    WriteCase("uuid-str", "uuid", UUID_1, UUID_1),
    WriteCase("inet-str", "inet", "10.0.0.1", "'10.0.0.1'"),
    WriteCase("inet-ipv6-str", "inet", "2001:db8::1", "'2001:db8::1'"),
    WriteCase("date-datetime", "date", datetime(2024, 6, 15, 18, 34), "'2024-06-15'"),
    WriteCase("time-str-nanoseconds", "time", "12:34:56.123456789", "'12:34:56.123456789'"),
    WriteCase("time-object", "time", time(12, 34, 56, 123456), "'12:34:56.123456'"),
    WriteCase("time-object-last", "time", time(23, 59, 59, 999999), "'23:59:59.999999'"),
    WriteCase(
        "timestamp-naive", "timestamp", datetime(2024, 6, 15, 12, 30, 0, 123000), "'2024-06-15 12:30:00.123+0000'"
    ),
    WriteCase(
        "timestamp-other-zone",
        "timestamp",
        datetime(2024, 6, 15, 15, 30, 0, 123000, tzinfo=timezone(timedelta(hours=3))),
        "'2024-06-15 12:30:00.123+0000'",
    ),
    WriteCase("duration-timedelta", "duration", timedelta(days=3, hours=4), "3d4h"),
    WriteCase("duration-tuple", "duration", (14, 3, 14706007008009), "1y2mo3d4h5m6s7ms8us9ns"),
    WriteCase(
        "duration-relativedelta",
        "duration",
        relativedelta(years=1, months=2, days=3, hours=4, minutes=5, seconds=6, microseconds=7008),
        "1y2mo3d4h5m6s7ms8us",
        DURATION,
        needs="dateutil",
    ),
    WriteCase("set-list", "set<int>", [3, 1, 2], "{1, 2, 3}"),
    WriteCase("map-pairs", "map<text, int>", [("a", 1), ("b", 2)], "{'a': 1, 'b': 2}"),
    WriteCase("vector-tuple", "vector<float, 3>", (1.5, 2.5, 3.5), "[1.5, 2.5, 3.5]", VECTOR),
]


# The values acsylla returns are bound back, except the empty values, the ones it can not return and the ones it
# returns with a part lost
ROUND_TRIP_CASES = [case for case in CASES if case.round_trip and case.lossless and not isinstance(case.value, Raises)]
ROUND_TRIP_NATIVE_CASES = [case for case in CASES if case.round_trip]


def column(cql_type):
    return "value_" + re.sub(r"\W+", "_", cql_type).strip("_")


def table(cql_type):
    # Vectors are in a table of their own, a server without them still runs the other cases
    return "cql_vectors" if cql_type.startswith("vector") else "cql_values"


def server_value(cql_type):
    """The expression the server returns the stored value with, the bytes for a native type."""
    if cql_type == "blob":
        return column(cql_type)
    if cql_type in NATIVE_TYPES:
        return f"{cql_type}AsBlob({column(cql_type)})"
    return f"toJson({column(cql_type)})"


def resolve(value):
    """Makes the values of the types that do not exist yet."""
    if isinstance(value, FunctionType):
        return value()
    if type(value) is list:
        return [resolve(v) for v in value]
    if type(value) is tuple:
        return tuple(resolve(v) for v in value)
    if type(value) is dict:
        return {resolve(k): resolve(v) for k, v in value.items()}
    return value


def same(actual, expected):
    """Equal and of the same type all the way down. NaN equals NaN, a Decimal keeps its exponent, the order of a map
    is the order of the server."""
    if type(actual) is not type(expected):
        return False
    if isinstance(expected, float):
        return actual == expected or (math.isnan(actual) and math.isnan(expected))
    if isinstance(expected, Decimal):
        return actual.as_tuple() == expected.as_tuple()
    if isinstance(expected, dict):
        return len(actual) == len(expected) and all(
            same(ak, ek) and same(av, ev) for (ak, av), (ek, ev) in zip(actual.items(), expected.items())
        )
    if isinstance(expected, (list, tuple)):
        return len(actual) == len(expected) and all(same(a, e) for a, e in zip(actual, expected))
    if isinstance(expected, (set, frozenset)):
        return actual == expected and sorted(map(repr, actual)) == sorted(map(repr, expected))
    return actual == expected


def params(cases, aspect):
    return [
        pytest.param(
            case,
            id=case.id,
            marks=[pytest.mark.xfail(strict=True, reason=case.todo[aspect])] if aspect in case.todo else [],
        )
        for case in cases
    ]


def write_params(cases):
    return [
        pytest.param(case, id=case.id, marks=[pytest.mark.xfail(strict=True, reason=case.todo)] if case.todo else [])
        for case in cases
    ]


COUNTER_UPDATE = "UPDATE cql_counters SET value_counter = value_counter + {}"

# Ids of the rows: the literal of a case, then what acsylla wrote
READ_ID = 0
ROUND_TRIP_ID = 10000
ROUND_TRIP_NATIVE_ID = 20000
WRITE_LITERAL_ID = 30000
WRITE_ID = 40000


def case_id(case):
    return CASES.index(case)


# The cases the server does not take the literal of -> its error, filled by the session fixture
UNSUPPORTED = {}


def skip_unsupported(case):
    if case in UNSUPPORTED:
        pytest.skip(f"The server does not take {case.literal}: {UNSUPPORTED[case]}")


@pytest.fixture(scope="class")
def keyspace():
    return "acsylla_cql_values"


@pytest.fixture(scope="class")
def host():
    return os.environ.get("ACSYLLA_TEST_HOST", "127.0.0.1")


@pytest.fixture(scope="class")
async def cluster(host):
    return create_cluster([host], connect_timeout=10.0, request_timeout=30.0, resolve_timeout=5.0, log_level="critical")


@pytest.fixture(scope="class")
async def session(cluster, keyspace):
    """The tables of all the cases with their literals written, without the Java functions of conftest, so it runs on
    ScyllaDB too."""
    setup = await cluster.create_session()
    await setup.execute(create_statement(f"DROP KEYSPACE IF EXISTS {keyspace}"))
    await setup.execute(
        create_statement(
            # SimpleStrategy does not work with the tablets of ScyllaDB
            f"CREATE KEYSPACE {keyspace} WITH REPLICATION = "
            "{'class': 'NetworkTopologyStrategy', 'replication_factor': 1}"
        )
    )
    await setup.close()

    session = await cluster.create_session(keyspace=keyspace)
    await session.execute(create_statement(ADDR))
    cql_types = sorted({case.cql_type for case in CASES} | {case.cql_type for case in WRITE_CASES})
    missing_tables = {}
    for name in ("cql_values", "cql_vectors"):
        columns = ", ".join(f"{column(t)} {t}" for t in cql_types if table(t) == name)
        try:
            await session.execute(create_statement(f"CREATE TABLE {name} (id int PRIMARY KEY, {columns})"))
        except errors.CassException as e:
            # A server without vectors
            missing_tables[name] = e
    await session.execute(create_statement("CREATE TABLE cql_counters (id int PRIMARY KEY, value_counter counter)"))

    UNSUPPORTED.clear()
    for row_id, case in [(READ_ID + i, case) for i, case in enumerate(CASES)] + [
        (WRITE_LITERAL_ID + i, case) for i, case in enumerate(WRITE_CASES)
    ]:
        try:
            if table(case.cql_type) in missing_tables:
                raise missing_tables[table(case.cql_type)]
            columns = f"{table(case.cql_type)} (id, {column(case.cql_type)})"
            insert = f"INSERT INTO {columns} VALUES ({row_id}, {case.literal})"
            await session.execute(create_statement(insert))
        except errors.CassException as e:
            # Cassandra has no empty values of the types added later, smallint, tinyint, date and time
            UNSUPPORTED[case] = e
    try:
        yield session
    finally:
        await session.close()


async def read(session, cql_type, row_id, native_types=False, expression=None):
    statement = create_statement(f"SELECT {expression or column(cql_type)} FROM {table(cql_type)} WHERE id = {row_id}")
    result = await session.execute(statement, native_types=native_types)
    return result.first()


async def write(session, cql_type, row_id, value):
    prepared = await session.create_prepared(f"INSERT INTO {table(cql_type)} (id, {column(cql_type)}) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind_list([row_id, value])
    await session.execute(statement)


async def assert_same_on_server(session, cql_type, row_id, expected_row_id):
    actual = (await read(session, cql_type, row_id, expression=server_value(cql_type)))[0]
    expected = (await read(session, cql_type, expected_row_id, expression=server_value(cql_type)))[0]
    assert actual == expected


class TestRead:
    async def check(self, session, case, expected, native_types):
        skip_unsupported(case)
        row = await read(session, case.cql_type, READ_ID + case_id(case), native_types=native_types)
        if isinstance(expected, Raises):
            with pytest.raises(expected.exception, match=expected.match):
                row.column_value(column(case.cql_type))
            return
        expected = resolve(expected)
        actual = row.column_value(column(case.cql_type))
        assert same(actual, expected), f"{actual!r} != {expected!r}"

    @pytest.mark.parametrize("case", params(CASES, "read"))
    async def test_default(self, session, case):
        await self.check(session, case, case.value, native_types=False)

    @pytest.mark.parametrize("case", params(CASES, "native"))
    async def test_native(self, session, case):
        await self.check(session, case, case.native, native_types=True)

    async def test_counter(self, session):
        await session.execute(create_statement(f"{COUNTER_UPDATE.format(5)} WHERE id = 1"))
        for native_types in (False, True):
            statement = create_statement("SELECT value_counter FROM cql_counters WHERE id = 1")
            result = await session.execute(statement, native_types=native_types)
            assert same(result.first().column_value("value_counter"), 5)


class TestWrite:
    @pytest.mark.parametrize("case", params(ROUND_TRIP_CASES, "write"))
    async def test_default(self, session, case):
        """The value acsylla returns is bound back."""
        skip_unsupported(case)
        await write(session, case.cql_type, ROUND_TRIP_ID + case_id(case), resolve(case.value))
        await assert_same_on_server(session, case.cql_type, ROUND_TRIP_ID + case_id(case), READ_ID + case_id(case))

    @pytest.mark.parametrize("case", params(ROUND_TRIP_NATIVE_CASES, "write native"))
    async def test_native(self, session, case):
        """The value acsylla returns with native_types is bound back."""
        skip_unsupported(case)
        await write(session, case.cql_type, ROUND_TRIP_NATIVE_ID + case_id(case), resolve(case.native))
        await assert_same_on_server(
            session, case.cql_type, ROUND_TRIP_NATIVE_ID + case_id(case), READ_ID + case_id(case)
        )

    @pytest.mark.parametrize("case", write_params(WRITE_CASES))
    async def test_other_values(self, session, case):
        """The other values a column accepts."""
        skip_unsupported(case)
        if case.needs:
            pytest.importorskip(case.needs)
        i = WRITE_CASES.index(case)
        await write(session, case.cql_type, WRITE_ID + i, resolve(case.value))
        await assert_same_on_server(session, case.cql_type, WRITE_ID + i, WRITE_LITERAL_ID + i)

    async def test_counter(self, session):
        await session.execute(create_statement(f"{COUNTER_UPDATE.format(5)} WHERE id = 2"))
        prepared = await session.create_prepared(f"{COUNTER_UPDATE.format('?')} WHERE id = ?")
        statement = prepared.bind()
        statement.bind_list([5, 3])
        await session.execute(statement)
        values = []
        for row_id in (2, 3):
            statement = create_statement(f"SELECT counterAsBlob(value_counter) FROM cql_counters WHERE id = {row_id}")
            values.append((await session.execute(statement)).first()[0])
        assert values[0] == values[1]


class TestRow:
    async def row(self, session):
        case = next(c for c in CASES if c.id == "int")
        statement = create_statement(f"SELECT id, value_int FROM cql_values WHERE id = {READ_ID + case_id(case)}")
        return (await session.execute(statement)).first()

    @pytest.mark.xfail(strict=True, reason=ROW)
    async def test_missing_attribute(self, session):
        row = await self.row(session)
        assert not hasattr(row, "missing")
        assert getattr(row, "missing", "default") == "default"
        with pytest.raises(AttributeError):
            row.missing
        with pytest.raises(errors.ColumnNotFound):
            row.missing

    @pytest.mark.xfail(strict=True, reason=ROW)
    async def test_as_named_tuple(self, session):
        row = await self.row(session)
        value = row.as_named_tuple()
        assert value._fields == ("id", "value_int")
        assert value.value_int == -2147483648
        assert tuple(value) == (READ_ID + case_id(next(c for c in CASES if c.id == "int")), -2147483648)
