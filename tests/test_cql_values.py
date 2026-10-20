"""CQL values checked against the server, not against acsylla itself.

Read: every value is written as a CQL literal, so the server parses it and acsylla only reads it.
Write: a value bound by acsylla must give the server the same bytes as the CQL literal of the case, compared with
typeAsBlob() for a native type and with toJson() for the others. The values acsylla returns, with and without
native_types, are bound back the same way.

The cases describe a session with legacy_types=False, the only one of acsylla 2.0.0, and the types of acsylla 1.x a
session with legacy_types=True keeps. A case that is not done yet is marked xfail(strict=True) with the stage of the
plan that does it, so the stage that makes it pass has to remove the mark.
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
import array
import copy
import ctypes
import gc
import ipaddress
import math
import os
import pickle
import pytest
import re
import struct
import uuid
import warnings
import weakref

pytestmark = pytest.mark.asyncio(loop_scope="class")

UTC = timezone.utc


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


# The value of a session with legacy_types=True is the same as with legacy_types=False
SAME = object()


@dataclass(frozen=True, eq=False)
class Case:
    """A value of `cql_type` written as the CQL `literal`, acsylla reads it as `value` and with native_types as
    `native`, a session with legacy_types=True as `legacy` and `legacy_native`, and binding them must give the server
    the same value."""

    id: str
    cql_type: str
    literal: str
    value: object
    native: object
    legacy: object = SAME
    legacy_native: object = SAME
    # What is not done yet: "read", "native", "write", "write native", "legacy", "legacy native", "legacy write" or
    # "legacy write native" -> the stage that does it. A legacy aspect of a case with the SAME value has the todo of
    # its aspect without legacy_types
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


def varint_bytes(number):
    """The two's complement of a varint, the value acsylla 1.x returns."""
    return number.to_bytes(((number if number >= 0 else ~number).bit_length() + 8) // 8, "big", signed=True)


def decimal_blob(text):
    """The blobAsDecimal() literal of a decimal: the server parses a long decimal literal through a double."""
    sign, digits, exponent = Decimal(text).as_tuple()
    unscaled = int("".join(map(str, digits))) * (-1 if sign else 1)
    return f"blobAsDecimal(0x{(-exponent).to_bytes(4, 'big', signed=True).hex()}{varint_bytes(unscaled).hex()})"


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
        legacy=varint_bytes(123456789012345678901234567890),
        legacy_native=varint_bytes(123456789012345678901234567890),
    ),
    Case(
        "varint-negative",
        "varint",
        "-123456789012345678901234567890",
        -123456789012345678901234567890,
        -123456789012345678901234567890,
        legacy=varint_bytes(-123456789012345678901234567890),
        legacy_native=varint_bytes(-123456789012345678901234567890),
    ),
    Case(
        "varint-minus-one",
        "varint",
        "-1",
        -1,
        -1,
        legacy=b"\xff",
        legacy_native=b"\xff",
    ),
    Case(
        "varint-zero",
        "varint",
        "0",
        0,
        0,
        legacy=b"\x00",
        legacy_native=b"\x00",
    ),
    # Up to 8 bytes a varint is read through int64
    Case(
        "varint-127",
        "varint",
        "127",
        127,
        127,
        legacy=varint_bytes(127),
        legacy_native=varint_bytes(127),
    ),
    Case(
        "varint-128",
        "varint",
        "128",
        128,
        128,
        legacy=varint_bytes(128),
        legacy_native=varint_bytes(128),
    ),
    Case(
        "varint-minus-128",
        "varint",
        "-128",
        -128,
        -128,
        legacy=varint_bytes(-128),
        legacy_native=varint_bytes(-128),
    ),
    Case(
        "varint-minus-129",
        "varint",
        "-129",
        -129,
        -129,
        legacy=varint_bytes(-129),
        legacy_native=varint_bytes(-129),
    ),
    Case(
        "varint-int64-max",
        "varint",
        "9223372036854775807",
        9223372036854775807,
        9223372036854775807,
        legacy=varint_bytes(9223372036854775807),
        legacy_native=varint_bytes(9223372036854775807),
    ),
    Case(
        "varint-int64-min",
        "varint",
        "-9223372036854775808",
        -9223372036854775808,
        -9223372036854775808,
        legacy=varint_bytes(-9223372036854775808),
        legacy_native=varint_bytes(-9223372036854775808),
    ),
    Case(
        "varint-9-bytes",
        "varint",
        "9223372036854775808",
        9223372036854775808,
        9223372036854775808,
        legacy=varint_bytes(9223372036854775808),
        legacy_native=varint_bytes(9223372036854775808),
    ),
    Case(
        "varint-9-bytes-negative",
        "varint",
        "-9223372036854775809",
        -9223372036854775809,
        -9223372036854775809,
        legacy=varint_bytes(-9223372036854775809),
        legacy_native=varint_bytes(-9223372036854775809),
    ),
    # A varint of 513 bytes, an int of Python has no size
    Case(
        "varint-4096-bits",
        "varint",
        str(2**4096),
        2**4096,
        2**4096,
        legacy=varint_bytes(2**4096),
        legacy_native=varint_bytes(2**4096),
    ),
    Case("decimal", "decimal", "1234.5678", Decimal("1234.5678"), "1234.5678"),
    Case("decimal-negative", "decimal", "-0.000001", Decimal("-0.000001"), "-0.000001"),
    Case("decimal-negative-scale", "decimal", "1E+10", Decimal("1E+10"), "1E+10"),
    Case("decimal-big-exponent", "decimal", "1.5E+30", Decimal("1.5E+30"), "1.5E+30"),
    Case("decimal-zero", "decimal", "0", Decimal("0"), "0"),
    Case("decimal-leading-zeros", "decimal", "0.05", Decimal("0.05"), "0.05"),
    Case("decimal-scientific", "decimal", "0.000000012345", Decimal("1.2345E-8"), "1.2345E-8"),
    # Up to 38 digits a decimal is read and written through 64 and 128-bit integers, longer ones through a Python int
    Case("decimal-18-digits", "decimal", "999999999999999999", Decimal("999999999999999999"), "999999999999999999"),
    Case("decimal-19-digits", "decimal", "9999999999999999999", Decimal("9999999999999999999"), "9999999999999999999"),
    Case(
        "decimal-18-decimal-places",
        "decimal",
        "1234.123456789012345678",
        Decimal("1234.123456789012345678"),
        "1234.123456789012345678",
    ),
    Case(
        "decimal-38-digits",
        "decimal",
        "-9999999999999999999999999999.9999999999",
        Decimal("-9999999999999999999999999999.9999999999"),
        "-9999999999999999999999999999.9999999999",
    ),
    Case(
        "decimal-39-digits",
        "decimal",
        "123456789012345678901234567890123456789",
        Decimal("123456789012345678901234567890123456789"),
        "123456789012345678901234567890123456789",
    ),
    Case(
        "decimal-long-scientific",
        "decimal",
        "1.23456789012345678901234567890E+40",
        Decimal("1.23456789012345678901234567890E+40"),
        "1.23456789012345678901234567890E+40",
    ),
    Case(
        "decimal-int64-min",
        "decimal",
        "-9223372036854775808",
        Decimal("-9223372036854775808"),
        "-9223372036854775808",
    ),
    Case(
        "decimal-precision",
        "decimal",
        "3.141592653589793115997963468544185161590576171875",
        Decimal("3.141592653589793115997963468544185161590576171875"),
        "3.141592653589793115997963468544185161590576171875",
    ),
    # What acsylla 1.2.0 wrote for Decimal("1234.5678"): the text of it in place of the unscaled value
    Case(
        "decimal-legacy",
        "decimal",
        "blobAsDecimal(0x00000004313233342e35363738)",
        Decimal("90750775191054255.4936"),
        "90750775191054255.4936",
        legacy=Decimal("1234.5678"),
        legacy_native="1234.5678",
    ),
    Case("uuid", "uuid", UUID_1, UUID(UUID_1), UUID_1, legacy=UUID_1),
    Case("timeuuid", "timeuuid", TIMEUUID_1, UUID(TIMEUUID_1), TIMEUUID_1, legacy=TIMEUUID_1),
    Case(
        "inet",
        "inet",
        "'192.168.1.100'",
        IPv4Address("192.168.1.100"),
        "192.168.1.100",
        legacy="192.168.1.100",
    ),
    Case("inet-ipv6", "inet", "'::1'", IPv6Address("::1"), "::1", legacy="::1"),
    Case(
        "inet-ipv6-long",
        "inet",
        "'2001:db8::ff00:42:8329'",
        IPv6Address("2001:db8::ff00:42:8329"),
        "2001:db8::ff00:42:8329",
        legacy="2001:db8::ff00:42:8329",
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
        Raises(ValueError, "the date 0000-01-01 is out of the years 1..9999"),
        "0000-01-01",
    ),
    Case(
        "date-before-year-zero",
        "date",
        "2146764119",  # -0001-12-31
        Raises(ValueError, "the date -0001-12-31 is out of the years 1..9999"),
        "-0001-12-31",
    ),
    Case(
        "date-first-cql",
        "date",
        "0",  # -5877641-06-23
        Raises(ValueError, "the date -5877641-06-23 is out of the years 1..9999"),
        "-5877641-06-23",
    ),
    Case(
        "date-after-python",
        "date",
        "2150416545",  # 10000-01-01
        Raises(ValueError, "the date 10000-01-01 is out of the years 1..9999"),
        "10000-01-01",
    ),
    Case(
        "date-last-cql",
        "date",
        "4294967295",  # 5881580-07-11
        Raises(ValueError, "the date 5881580-07-11 is out of the years 1..9999"),
        "5881580-07-11",
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
        # acsylla 1.x read it through a float, it gave .998
    ),
    Case(
        "timestamp-before-python",
        "timestamp",
        "-62135596800001",
        Raises(ValueError, "the timestamp 0000-12-31 23:59:59.999Z is out of the years 1..9999"),
        "0000-12-31 23:59:59.999Z",
    ),
    Case(
        "timestamp-before-year-zero",
        "timestamp",
        "-62167219200001",
        Raises(ValueError, "the timestamp -0001-12-31 23:59:59.999Z is out of the years 1..9999"),
        "-0001-12-31 23:59:59.999Z",
    ),
    Case(
        "timestamp-after-python",
        "timestamp",
        "253402300800000",
        Raises(ValueError, "the timestamp 10000-01-01 00:00:00.000Z is out of the years 1..9999"),
        "10000-01-01 00:00:00.000Z",
    ),
    Case(
        "duration",
        "duration",
        "1y2mo3d4h5m6s7ms8us9ns",
        duration(14, 3, 14706007008009),
        "1y2mo3d4h5m6s7ms8us9ns",
        legacy="1y2mo3d4h5m6s7ms8us9ns",
        legacy_native=(14, 3, 14706007008009),
    ),
    Case(
        "duration-negative",
        "duration",
        "-1d",
        duration(0, -1, 0),
        "-1d",
        legacy="-1d",
        legacy_native=(0, -1, 0),
    ),
    Case(
        "duration-hours",
        "duration",
        "25h",
        duration(0, 0, 90000000000000),
        "25h",
        legacy="25h",
        legacy_native=(0, 0, 90000000000000),
    ),
    Case(
        "duration-zero",
        "duration",
        "0s",
        duration(0, 0, 0),
        "0s",
        # acsylla 1.x read a zero duration as "" and did not take it back, it is taken back as 0s
        legacy="",
        legacy_native=(0, 0, 0),
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
    Case("list-uuid", "list<uuid>", f"[{UUID_1}]", [UUID(UUID_1)], [UUID_1], legacy=[UUID_1]),
    Case(
        "map-timeuuid-inet",
        "map<timeuuid, inet>",
        f"{{{TIMEUUID_1}: '10.0.0.1'}}",
        {UUID(TIMEUUID_1): IPv4Address("10.0.0.1")},
        {TIMEUUID_1: "10.0.0.1"},
        legacy={TIMEUUID_1: "10.0.0.1"},
    ),
    Case(
        "list-varint",
        "list<varint>",
        "[1, -1, 123456789012345678901234567890]",
        [1, -1, 123456789012345678901234567890],
        [1, -1, 123456789012345678901234567890],
        legacy=[b"\x01", b"\xff", varint_bytes(123456789012345678901234567890)],
        legacy_native=[b"\x01", b"\xff", varint_bytes(123456789012345678901234567890)],
    ),
    Case(
        "set-decimal",
        "set<decimal>",
        "{1.5, 2.25}",
        {Decimal("1.5"), Decimal("2.25")},
        {"1.5", "2.25"},
    ),
    Case(
        "list-duration",
        "list<duration>",
        "[1d, 2h]",
        [duration(0, 1, 0), duration(0, 0, 7200000000000)],
        ["1d", "2h"],
        legacy=["1d", "2h"],
        legacy_native=[(0, 1, 0), (0, 0, 7200000000000)],
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
    Case("map-tuple-key", "map<frozen<tuple<int, text>>, int>", "{(1, 'x'): 10}", {(1, "x"): 10}, {(1, "x"): 10}),
    # A value of a collection out of the years of Python raises too
    Case(
        "list-date-after-python",
        "list<date>",
        "[2150416545]",  # 10000-01-01
        Raises(ValueError, "the date 10000-01-01 is out of the years 1..9999"),
        ["10000-01-01"],
    ),
    Case(
        "set-list",
        "set<frozen<list<int>>>",
        "{[1, 2], [3]}",
        [[1, 2], [3]],
        [[1, 2], [3]],
    ),
    Case(
        "set-set",
        "set<frozen<set<int>>>",
        "{{1, 2}}",
        [{1, 2}],
        [{1, 2}],
    ),
    Case(
        "set-map",
        "set<frozen<map<int, int>>>",
        "{{1: 2}}",
        [{1: 2}],
        [{1: 2}],
    ),
    Case(
        "set-udt",
        "set<frozen<addr>>",
        "{{street: 'a', num: 1}}",
        [{"street": "a", "num": 1}],
        [{"street": "a", "num": 1}],
    ),
    Case(
        "set-tuple-list",
        "set<frozen<tuple<int, frozen<list<int>>>>>",
        "{(1, [2])}",
        [(1, [2])],
        [(1, [2])],
    ),
    Case(
        "map-list-key",
        "map<frozen<list<int>>, int>",
        "{[1, 2]: 10}",
        [([1, 2], 10)],
        [([1, 2], 10)],
    ),
    Case(
        "map-udt-key",
        "map<frozen<addr>, int>",
        "{{street: 'b', num: 2}: 20}",
        [({"street": "b", "num": 2}, 20)],
        [({"street": "b", "num": 2}, 20)],
    ),
    Case(
        "vector-float",
        "vector<float, 3>",
        "[1.5, 2.5, 3.5]",
        [1.5, 2.5, 3.5],
        [1.5, 2.5, 3.5],
        legacy=struct.pack(">3f", 1.5, 2.5, 3.5),
        legacy_native=struct.pack(">3f", 1.5, 2.5, 3.5),
    ),
    Case(
        "vector-int",
        "vector<int, 2>",
        "[1, -2]",
        [1, -2],
        [1, -2],
        legacy=struct.pack(">2i", 1, -2),
        legacy_native=struct.pack(">2i", 1, -2),
    ),
    Case(
        "vector-text",
        "vector<text, 2>",
        "['a', 'bc']",
        ["a", "bc"],
        ["a", "bc"],
        legacy=b"\x01a\x02bc",
        legacy_native=b"\x01a\x02bc",
    ),
    Case(
        "vector-double",
        "vector<double, 2>",
        "[1.5, -2.25]",
        [1.5, -2.25],
        [1.5, -2.25],
        legacy=struct.pack(">2d", 1.5, -2.25),
        legacy_native=struct.pack(">2d", 1.5, -2.25),
    ),
    Case(
        "vector-bigint",
        "vector<bigint, 2>",
        f"[{2**62}, -1]",
        [2**62, -1],
        [2**62, -1],
        legacy=struct.pack(">2q", 2**62, -1),
        legacy_native=struct.pack(">2q", 2**62, -1),
    ),
    Case(
        "vector-smallint",
        "vector<smallint, 2>",
        "[-32768, 32767]",
        [-32768, 32767],
        [-32768, 32767],
        # Each smallint and tinyint of a vector after its size
        legacy=b"\x02\x80\x00\x02\x7f\xff",
        legacy_native=b"\x02\x80\x00\x02\x7f\xff",
    ),
    Case(
        "vector-tinyint",
        "vector<tinyint, 2>",
        "[-128, 127]",
        [-128, 127],
        [-128, 127],
        legacy=b"\x01\x80\x01\x7f",
        legacy_native=b"\x01\x80\x01\x7f",
    ),
    Case(
        "vector-boolean",
        "vector<boolean, 2>",
        "[true, false]",
        [True, False],
        [True, False],
        legacy=b"\x01\x00",
        legacy_native=b"\x01\x00",
    ),
    Case(
        "vector-uuid",
        "vector<uuid, 1>",
        f"[{UUID_1}]",
        [UUID(UUID_1)],
        [UUID_1],
        legacy=UUID(UUID_1).bytes,
        legacy_native=UUID(UUID_1).bytes,
    ),
    Case(
        "vector-varint",
        "vector<varint, 2>",
        f"[1, {-(2**70)}]",
        [1, -(2**70)],
        [1, -(2**70)],
        legacy=b"\x01\x01" + bytes([len(varint_bytes(-(2**70)))]) + varint_bytes(-(2**70)),
        legacy_native=b"\x01\x01" + bytes([len(varint_bytes(-(2**70)))]) + varint_bytes(-(2**70)),
    ),
    # The size of the vectors of embeddings
    Case(
        "vector-float-768",
        "vector<float, 768>",
        "[" + ", ".join(f"{i}.5" for i in range(768)) + "]",
        [i + 0.5 for i in range(768)],
        [i + 0.5 for i in range(768)],
        legacy=struct.pack(">768f", *(i + 0.5 for i in range(768))),
        legacy_native=struct.pack(">768f", *(i + 0.5 for i in range(768))),
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
        round_trip=False,
        legacy=b"",
        legacy_native=b"",
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
    WriteCase("decimal-str", "decimal", "1234.5678", "1234.5678"),
    WriteCase("decimal-str-exponent", "decimal", "1E+10", "1E+10"),
    WriteCase("decimal-str-lowercase-exponent", "decimal", "1.5e3", "1.5E+3"),
    WriteCase("decimal-int", "decimal", 5, "5"),
    WriteCase("decimal-big-int", "decimal", 10**30, "1000000000000000000000000000000"),
    WriteCase("decimal-negative-zero", "decimal", Decimal("-0"), "0"),
    WriteCase("decimal-float", "decimal", 3.14, "3.14"),
    # A str is parsed as it is, Decimal() parses the texts with spaces or underscores
    WriteCase("decimal-str-plus", "decimal", "+5", "5"),
    WriteCase("decimal-str-leading-point", "decimal", ".5", "0.5"),
    WriteCase("decimal-str-trailing-point", "decimal", "5.", "5"),
    WriteCase("decimal-str-leading-zeros", "decimal", "007.50", "7.50"),
    WriteCase("decimal-str-negative-exponent", "decimal", "-1.5e-3", "-0.0015"),
    WriteCase("decimal-str-zero-exponent", "decimal", "0E+3", "0E+3"),
    WriteCase("decimal-str-spaces", "decimal", " 1.5 ", "1.5"),
    WriteCase("decimal-str-underscores", "decimal", "1_000.5", "1000.5"),
    # More than 38 digits, their two's complement is made of limbs of 32 bits
    WriteCase(
        "decimal-str-long-negative",
        "decimal",
        "-1234567890123456789012345678901234567890.5",
        "-1234567890123456789012345678901234567890.5",
    ),
    WriteCase(
        "decimal-long-negative",
        "decimal",
        Decimal("-1234567890123456789012345678901234567890.5"),
        "-1234567890123456789012345678901234567890.5",
    ),
    WriteCase(
        "decimal-long-exponent",
        "decimal",
        "1234567890123456789012345678901234567890E-45",
        "1.234567890123456789012345678901234567890E-6",
    ),
    WriteCase("decimal-2-128", "decimal", Decimal(2**128), str(2**128)),
    WriteCase("decimal-minus-2-128", "decimal", Decimal(-(2**128)), str(-(2**128))),
    WriteCase("decimal-minus-2-128-plus-1", "decimal", Decimal(-(2**128) + 1), str(-(2**128) + 1)),
    WriteCase(
        "decimal-1000-digits",
        "decimal",
        Decimal("9" * 500 + "." + "9" * 500),
        decimal_blob("9" * 500 + "." + "9" * 500),
    ),
    WriteCase("decimal-1000-digits-negative", "decimal", "-" + "1" * 999 + "7", "-" + "1" * 999 + "7"),
    # More digits than the buffers on the stack take
    WriteCase("decimal-1300-digits", "decimal", "1" * 650 + "." + "3" * 650, decimal_blob("1" * 650 + "." + "3" * 650)),
    # More than 38 digits after leading zeros, a point among them, a sign and an exponent
    WriteCase(
        "decimal-long-leading-zeros",
        "decimal",
        "0" * 10 + "1" * 50 + "." + "2" * 13,
        decimal_blob("0" * 10 + "1" * 50 + "." + "2" * 13),
    ),
    WriteCase("decimal-long-plus-exponent", "decimal", "+" + "9" * 60 + "e-5", decimal_blob("9" * 60 + "e-5")),
    # An ascii str is bound as it is with its length, a NUL in it too
    WriteCase("ascii-nul", "ascii", "a\x00b", "blobAsAscii(0x610062)"),
    WriteCase("ascii-bytes", "ascii", b"ab", "'ab'"),
    WriteCase("list-ascii", "list<ascii>", ["ab", "cd"], "['ab', 'cd']"),
    WriteCase("tuple-ascii", "tuple<ascii, int>", ("ab", 1), "('ab', 1)"),
    # bytes are the two's complement of the number, as before
    WriteCase("varint-bytes", "varint", b"\x7b", "123"),
    WriteCase("varint-str", "varint", "123", "123"),
    WriteCase("varint-str-negative", "varint", "-123", "-123"),
    # The shortest two's complement: 128 is 0x0080, -129 is 0xff7f
    WriteCase("varint-128", "varint", 128, "128"),
    WriteCase("varint-minus-129", "varint", -129, "-129"),
    WriteCase("varint-big", "varint", 2**100, str(2**100)),
    WriteCase("varint-4096-bits-negative", "varint", -(2**4096), str(-(2**4096))),
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
    WriteCase(
        "timestamp-negative-zone",
        "timestamp",
        datetime(2024, 6, 15, 7, 0, 0, 123000, tzinfo=timezone(-timedelta(hours=5, minutes=30))),
        "'2024-06-15 12:30:00.123+0000'",
    ),
    # The microseconds of a datetime are cut to its milliseconds, the last microsecond of 1969 is -1 ms
    WriteCase("timestamp-before-epoch", "timestamp", datetime(1969, 12, 31, 23, 59, 59, 999999, tzinfo=UTC), "-1"),
    WriteCase("timestamp-str-before-year-zero", "timestamp", "-0001-12-31 23:59:59.999Z", "-62167219200001"),
    WriteCase("duration-timedelta", "duration", timedelta(days=3, hours=4), "3d4h"),
    WriteCase("duration-tuple", "duration", (14, 3, 14706007008009), "1y2mo3d4h5m6s7ms8us9ns"),
    WriteCase("duration-object", "duration", duration(-14, -3, -14706007008009), "-1y2mo3d4h5m6s7ms8us9ns"),
    # The days of a negative timedelta are negative and its seconds positive, a duration has one sign
    WriteCase("duration-negative-timedelta", "duration", -timedelta(days=1, hours=1), "-1d1h"),
    WriteCase("duration-empty-str", "duration", "", "0s"),
    WriteCase(
        "duration-relativedelta",
        "duration",
        relativedelta(years=1, months=2, days=3, hours=4, minutes=5, seconds=6, microseconds=7008),
        "1y2mo3d4h5m6s7ms8us",
        needs="dateutil",
    ),
    WriteCase("set-list", "set<int>", [3, 1, 2], "{1, 2, 3}"),
    WriteCase("map-pairs", "map<text, int>", [("a", 1), ("b", 2)], "{'a': 1, 'b': 2}"),
    WriteCase("vector-tuple", "vector<float, 3>", (1.5, 2.5, 3.5), "[1.5, 2.5, 3.5]"),
    # A buffer of numbers is copied, its items are not made one by one
    WriteCase("vector-array", "vector<float, 3>", array.array("f", [1.5, 2.5, 3.5]), "[1.5, 2.5, 3.5]"),
    WriteCase("vector-array-double", "vector<double, 2>", array.array("d", [1.5, -2.25]), "[1.5, -2.25]"),
    WriteCase("vector-array-int", "vector<int, 2>", array.array("i", [1, -2]), "[1, -2]"),
    WriteCase("vector-array-bigint", "vector<bigint, 2>", array.array("q", [2**62, -1]), f"[{2**62}, -1]"),
    WriteCase(
        "vector-memoryview", "vector<float, 3>", memoryview(array.array("f", [1.5, 2.5, 3.5])), "[1.5, 2.5, 3.5]"
    ),
    WriteCase(
        "vector-big-endian-buffer",
        "vector<float, 3>",
        (ctypes.c_float.__ctype_be__ * 3)(1.5, 2.5, 3.5),
        "[1.5, 2.5, 3.5]",
    ),
    WriteCase(
        "vector-little-endian-buffer",
        "vector<float, 3>",
        (ctypes.c_float.__ctype_le__ * 3)(1.5, 2.5, 3.5),
        "[1.5, 2.5, 3.5]",
    ),
    # A buffer of another format or with a step is read item by item
    WriteCase("vector-array-other-format", "vector<float, 3>", array.array("d", [1.5, 2.5, 3.5]), "[1.5, 2.5, 3.5]"),
    WriteCase(
        "vector-strided-buffer",
        "vector<float, 3>",
        memoryview(array.array("f", [1.5, 0, 2.5, 0, 3.5, 0]))[::2],
        "[1.5, 2.5, 3.5]",
    ),
    WriteCase("vector-uuid-str", "vector<uuid, 1>", [UUID_1], f"[{UUID_1}]"),
]


# The values acsylla returns are bound back, except the empty values, the ones it can not return and the ones it
# returns with a part lost
ROUND_TRIP_CASES = [case for case in CASES if case.round_trip and case.lossless and not isinstance(case.value, Raises)]
ROUND_TRIP_NATIVE_CASES = [case for case in CASES if case.round_trip]
# A session with legacy_types=True writes decimals as the text of acsylla 1.x, they are checked apart
LEGACY_ROUND_TRIP_CASES = [case for case in ROUND_TRIP_CASES if "decimal" not in case.cql_type]
LEGACY_ROUND_TRIP_NATIVE_CASES = [case for case in ROUND_TRIP_NATIVE_CASES if "decimal" not in case.cql_type]
LEGACY_DECIMAL_CASES = [case for case in CASES if case.cql_type == "decimal" and isinstance(case.value, Decimal)]


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


# A legacy aspect of a case with the SAME value has the todo of this aspect without legacy_types
LEGACY_ASPECTS = {
    "legacy": ("legacy", "read"),
    "legacy native": ("legacy_native", "native"),
    "legacy write": ("legacy", "write"),
    "legacy write native": ("legacy_native", "write native"),
}


def todo_of(case, aspect):
    if aspect in case.todo:
        return case.todo[aspect]
    if aspect in LEGACY_ASPECTS:
        name, plain_aspect = LEGACY_ASPECTS[aspect]
        if getattr(case, name) is SAME:
            return case.todo.get(plain_aspect)
    return None


def params(cases, aspect):
    marked = []
    for case in cases:
        todo = todo_of(case, aspect)
        marks = [pytest.mark.xfail(strict=True, reason=todo)] if todo else []
        marked.append(pytest.param(case, id=case.id, marks=marks))
    return marked


def legacy_value(case, native_types=False):
    """The value a session with legacy_types=True reads."""
    value = case.legacy_native if native_types else case.legacy
    if value is SAME:
        return case.native if native_types else case.value
    return value


def legacy_decimal_bytes(value):
    """decimalAsBlob() of the text acsylla 1.x wrote for a decimal, its digits after the point as the scale."""
    text = str(value)
    if "E" in text:
        text = format(value, "f")
    scale = len(text.partition(".")[2])
    return scale.to_bytes(4, "big", signed=True) + text.encode()


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
LEGACY_ROUND_TRIP_ID = 50000
LEGACY_ROUND_TRIP_NATIVE_ID = 60000
LEGACY_DECIMAL_ID = 70000
DECIMAL_FORMAT_ID = 80000
LEGACY_DECIMAL_STR_ID = 90000

# Values of a decimal column that are not decimals of CQL
DECIMAL_ERRORS = [
    "",
    ".",
    "-",
    "1e",
    "1e+",
    "1.2.3",
    "--1",
    "1e5x",
    "bad",
    "NaN",
    "Infinity",
    "1E+99999999999",
    Decimal("NaN"),
    Decimal("-Infinity"),
    float("nan"),
    float("inf"),
    True,
]
# A session with legacy_types=True writes these str as the text of their Decimal
LEGACY_DECIMAL_STRS = [
    "1234.5678",
    "-0.000001",
    "0",
    "-0",
    "0.0000001",
    "-0.50",
    "007.5",
    "+5",
    "1e5",
    "-1.5E-3",
    " 1.5 ",
]
# and these float as the text of the Decimal of their str()
LEGACY_DECIMAL_FLOATS = [3.14, -0.5, 100.0, 1e-07, 1e16]


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
async def session(cluster, keyspace, request):
    """The tables of all the cases with their literals written, without the Java functions of conftest, so it runs on
    ScyllaDB too. The session has the legacy_types of its test class, False by default."""
    setup = await cluster.create_session(legacy_types=False)
    await setup.execute(create_statement(f"DROP KEYSPACE IF EXISTS {keyspace}"))
    await setup.execute(
        create_statement(
            # SimpleStrategy does not work with the tablets of ScyllaDB
            f"CREATE KEYSPACE {keyspace} WITH REPLICATION = "
            "{'class': 'NetworkTopologyStrategy', 'replication_factor': 1}"
        )
    )
    await setup.close()

    session = await cluster.create_session(keyspace=keyspace, legacy_types=getattr(request.cls, "legacy_types", False))
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


async def check_read(session, case, expected, native_types):
    skip_unsupported(case)
    row = await read(session, case.cql_type, READ_ID + case_id(case), native_types=native_types)
    if isinstance(expected, Raises):
        with pytest.raises(expected.exception, match=expected.match):
            row.column_value(column(case.cql_type))
        return
    expected = resolve(expected)
    actual = row.column_value(column(case.cql_type))
    assert same(actual, expected), f"{actual!r} != {expected!r}"


class TestRead:
    @pytest.mark.parametrize("case", params(CASES, "read"))
    async def test_default(self, session, case):
        await check_read(session, case, case.value, native_types=False)

    @pytest.mark.parametrize("case", params(CASES, "native"))
    async def test_native(self, session, case):
        await check_read(session, case, case.native, native_types=True)

    async def test_counter(self, session):
        await session.execute(create_statement(f"{COUNTER_UPDATE.format(5)} WHERE id = 1"))
        for native_types in (False, True):
            statement = create_statement("SELECT value_counter FROM cql_counters WHERE id = 1")
            result = await session.execute(statement, native_types=native_types)
            assert same(result.first().column_value("value_counter"), 5)


class TestUUID:
    """A uuid.UUID made from its slots is the one of its constructor."""

    @pytest.mark.parametrize("case_name", ["uuid", "timeuuid"])
    async def test_object(self, session, case_name):
        case = next(c for c in CASES if c.id == case_name)
        value = (await read(session, case.cql_type, READ_ID + case_id(case)))[0]
        expected = UUID(case.literal)
        assert type(value) is UUID
        assert value == expected and hash(value) == hash(expected) and value.int == expected.int
        assert str(value) == case.literal and repr(value) == repr(expected)
        assert value.is_safe is uuid.SafeUUID.unknown
        assert value.version == expected.version
        if case_name == "timeuuid":
            assert value.time == expected.time
        assert pickle.loads(pickle.dumps(value)) == expected
        assert copy.copy(value) == expected and copy.deepcopy(value) == expected
        assert {value: 1}[expected] == 1
        # Freed with its last reference
        reference = weakref.ref(value)
        del value
        gc.collect()
        assert reference() is None


class TestInet:
    """An IPv4Address or IPv6Address made from its slots is the one of its constructor."""

    @pytest.mark.parametrize("case_name", ["inet", "inet-ipv6", "inet-ipv6-long"])
    async def test_object(self, session, case_name):
        case = next(c for c in CASES if c.id == case_name)
        value = (await read(session, case.cql_type, READ_ID + case_id(case)))[0]
        expected = case.value
        assert type(value) is type(expected)
        assert value == expected and hash(value) == hash(expected) and int(value) == int(expected)
        assert str(value) == str(expected) and repr(value) == repr(expected)
        assert value.packed == expected.packed and value.version == expected.version
        assert value.is_private == expected.is_private and value.is_loopback == expected.is_loopback
        assert value.reverse_pointer == expected.reverse_pointer
        if value.version == 6:
            assert value.scope_id is None
        assert pickle.loads(pickle.dumps(value)) == expected
        assert copy.copy(value) == expected and copy.deepcopy(value) == expected
        assert {value: 1}[expected] == 1 and value in ipaddress.ip_network(f"{expected}/{expected.max_prefixlen}")
        # Freed with its last reference. A value of its own, the lru_cache of is_private and is_loopback keeps the one
        # above
        value = (await read(session, case.cql_type, READ_ID + case_id(case)))[0]
        reference = weakref.ref(value)
        del value
        gc.collect()
        assert reference() is None


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

    @pytest.mark.parametrize(
        "value, error",
        [
            ([1.5, 2.5], ValueError),
            ([1.5, 2.5, 3.5, 4.5], ValueError),
            ("abc", ValueError),
            ([1.5, "x", 3.5], TypeError),
            (array.array("f", [1.5, 2.5]), ValueError),
        ],
    )
    async def test_vector_errors(self, session, value, error):
        if "cql_vectors" not in {table(c.cql_type) for c in CASES if c not in UNSUPPORTED}:
            pytest.skip("The server has no vectors")
        with pytest.raises(error):
            await write(session, "vector<float, 3>", WRITE_ID - 1, value)

    @pytest.mark.parametrize("value", DECIMAL_ERRORS, ids=repr)
    async def test_decimal_errors(self, session, value):
        with pytest.raises(ValueError):
            await write(session, "decimal", WRITE_ID - 1, value)

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

    async def test_missing_attribute(self, session):
        row = await self.row(session)
        assert not hasattr(row, "missing")
        assert getattr(row, "missing", "default") == "default"
        with pytest.raises(AttributeError):
            row.missing
        with pytest.raises(errors.ColumnNotFound):
            row.missing

    async def test_as_named_tuple(self, session):
        """The tuple of (name, value) pairs of the columns, a dict is made of it."""
        row = await self.row(session)
        row_id = READ_ID + case_id(next(c for c in CASES if c.id == "int"))
        assert row.as_named_tuple() == (("id", row_id), ("value_int", -2147483648))
        assert dict(row.as_named_tuple()) == row.as_dict()

    async def test_as_named_tuple_gc(self, session):
        """The GC does not track the pairs of values it does not track, it tracks a pair of a list and the row."""
        row = await self.row(session)
        assert not gc.is_tracked(row.as_named_tuple())
        assert not any(gc.is_tracked(pair) for pair in row.as_named_tuple())
        row_id = READ_ID + case_id(next(c for c in CASES if c.id == "list"))
        statement = create_statement(f"SELECT id, value_list_int FROM cql_values WHERE id = {row_id}")
        value = (await session.execute(statement)).first().as_named_tuple()
        assert value == (("id", row_id), ("value_list_int", [3, 1, 2]))
        assert gc.is_tracked(value) and [gc.is_tracked(pair) for pair in value] == [False, True]

    async def test_value_error(self, session):
        """A value a row can not read raises its ValueError, read in any way."""
        case = next(c for c in CASES if c.id == "date-year-zero")
        skip_unsupported(case)
        statement = create_statement(f"SELECT id, value_date FROM cql_values WHERE id = {READ_ID + case_id(case)}")
        row = (await session.execute(statement)).first()
        reads = [
            row.as_tuple,
            row.as_list,
            row.as_dict,
            row.as_named_tuple,
            lambda: row[1],
            lambda: row["value_date"],
            lambda: list(row.values()),
        ]
        for read_row in reads:
            with pytest.raises(ValueError, match="the date 0000-01-01 is out of the years 1..9999"):
                read_row()


class TestLegacyDecimal:
    async def test_read(self, session):
        """The decimal acsylla 1.2.0 wrote for Decimal("1234.5678"), read with and without native_types."""
        case = next(c for c in CASES if c.id == "decimal-legacy")
        skip_unsupported(case)
        for native_types in (False, True):
            row = await read(session, case.cql_type, READ_ID + case_id(case), native_types=native_types)
            assert same(acsylla.decode_legacy_decimal(row[0]), Decimal("1234.5678"))

    @pytest.mark.parametrize(
        "text",
        ["1234.5678", "-0.000001", "+5", "007", "3.141592653589793115997963468544185161590576171875"],
    )
    async def test_values(self, text):
        """The text of a decimal acsylla 1.2.0 wrote in place of its unscaled value."""
        scale = len(text.partition(".")[2])
        legacy = Decimal(f"{int.from_bytes(text.encode(), 'big', signed=True)}E-{scale}")
        assert same(acsylla.decode_legacy_decimal(legacy), Decimal(text))
        assert same(acsylla.decode_legacy_decimal(str(legacy)), Decimal(text))

    @pytest.mark.parametrize("value", [Decimal("1234.5678"), Decimal("0"), Decimal("1E+10"), Decimal("NaN"), None])
    async def test_not_legacy(self, value):
        assert acsylla.decode_legacy_decimal(value) is None

    async def test_looks_legacy(self):
        """12594 is the text "12" with the scale 0, so only the values acsylla 1.2.0 wrote may be passed."""
        assert same(acsylla.decode_legacy_decimal(Decimal("12594")), Decimal("12"))


class TestLegacyRead:
    """A session with legacy_types=True reads the types of acsylla 1.x."""

    legacy_types = True

    @pytest.mark.parametrize("case", params(CASES, "legacy"))
    async def test_default(self, session, case):
        await check_read(session, case, legacy_value(case), native_types=False)

    @pytest.mark.parametrize("case", params(CASES, "legacy native"))
    async def test_native(self, session, case):
        await check_read(session, case, legacy_value(case, native_types=True), native_types=True)


class TestLegacyRow(TestRow):
    """A row of a session with legacy_types=True is read in the same way."""

    legacy_types = True


class TestLegacyWrite:
    """A session with legacy_types=True binds the types of acsylla 1.x, decimals as their text."""

    legacy_types = True

    @pytest.mark.parametrize("case", params(LEGACY_ROUND_TRIP_CASES, "legacy write"))
    async def test_default(self, session, case):
        skip_unsupported(case)
        await write(session, case.cql_type, LEGACY_ROUND_TRIP_ID + case_id(case), resolve(legacy_value(case)))
        await assert_same_on_server(
            session, case.cql_type, LEGACY_ROUND_TRIP_ID + case_id(case), READ_ID + case_id(case)
        )

    @pytest.mark.parametrize("case", params(LEGACY_ROUND_TRIP_NATIVE_CASES, "legacy write native"))
    async def test_native(self, session, case):
        skip_unsupported(case)
        row_id = LEGACY_ROUND_TRIP_NATIVE_ID + case_id(case)
        await write(session, case.cql_type, row_id, resolve(legacy_value(case, native_types=True)))
        await assert_same_on_server(session, case.cql_type, row_id, READ_ID + case_id(case))

    @pytest.mark.parametrize("case", params(LEGACY_DECIMAL_CASES, "legacy write"))
    async def test_decimal(self, session, case):
        """The text of the decimal, as acsylla 1.x wrote it, and read back as acsylla 1.x read it."""
        row_id = LEGACY_DECIMAL_ID + case_id(case)
        await write(session, "decimal", row_id, case.value)
        assert (await read(session, "decimal", row_id, expression=server_value("decimal")))[0] == legacy_decimal_bytes(
            case.value
        )
        assert (await read(session, "decimal", row_id))[0] == case.value

    @pytest.mark.parametrize("text", LEGACY_DECIMAL_STRS)
    async def test_decimal_str(self, session, text):
        """The text of the Decimal of a str, a plain one as it is without making its Decimal."""
        row_id = LEGACY_DECIMAL_STR_ID + LEGACY_DECIMAL_STRS.index(text)
        await write(session, "decimal", row_id, text)
        assert (await read(session, "decimal", row_id, expression=server_value("decimal")))[0] == legacy_decimal_bytes(
            Decimal(text)
        )

    @pytest.mark.parametrize("value", LEGACY_DECIMAL_FLOATS)
    async def test_decimal_float(self, session, value):
        row_id = LEGACY_DECIMAL_STR_ID + len(LEGACY_DECIMAL_STRS) + LEGACY_DECIMAL_FLOATS.index(value)
        await write(session, "decimal", row_id, value)
        assert (await read(session, "decimal", row_id, expression=server_value("decimal")))[0] == legacy_decimal_bytes(
            Decimal(str(value))
        )

    @pytest.mark.parametrize("value", DECIMAL_ERRORS, ids=repr)
    async def test_decimal_errors(self, session, value):
        with pytest.raises(ValueError):
            await write(session, "decimal", LEGACY_DECIMAL_STR_ID - 1, value)


class TestDecimalFormat:
    """A session executes the decimals bound for its own legacy_types only."""

    INSERT = "INSERT INTO cql_values (id, value_decimal) VALUES (?, ?)"

    async def legacy_session(self, cluster, keyspace):
        with pytest.warns(FutureWarning, match="acsylla 2.0.0 will only have legacy_types=False"):
            return await cluster.create_session(keyspace=keyspace)

    async def test_warning(self, cluster, keyspace):
        legacy = await self.legacy_session(cluster, keyspace)
        await legacy.close()
        with warnings.catch_warnings():
            warnings.simplefilter("error", FutureWarning)
            session = await cluster.create_session(keyspace=keyspace, legacy_types=False)
        await session.close()
        assert legacy.legacy_types is True
        assert session.legacy_types is False

    async def test_without_session(self, cluster, keyspace, session):
        """A statement without a session binds decimals as acsylla 1.x did."""
        statement = create_statement(self.INSERT, parameters=2)
        statement.bind_list([DECIMAL_FORMAT_ID, Decimal("1.5")])
        with pytest.raises(ValueError, match="this session has legacy_types=False"):
            await session.execute(statement)
        legacy = await self.legacy_session(cluster, keyspace)
        try:
            await legacy.execute(statement)
        finally:
            await legacy.close()

    async def test_other_session(self, cluster, keyspace, session):
        statement = session.query(self.INSERT, parameters=[DECIMAL_FORMAT_ID + 1, Decimal("1.5")])
        legacy = await self.legacy_session(cluster, keyspace)
        try:
            with pytest.raises(ValueError, match="this session has legacy_types=True"):
                await legacy.execute(statement)
        finally:
            await legacy.close()
        await session.execute(statement)

    async def test_without_decimals(self, session):
        statement = create_statement("INSERT INTO cql_values (id, value_int) VALUES (?, ?)", parameters=2)
        statement.bind_list([DECIMAL_FORMAT_ID + 2, 5])
        await session.execute(statement)

    async def test_batch(self, session):
        statement = create_statement(self.INSERT, parameters=2)
        statement.bind_list([DECIMAL_FORMAT_ID + 3, Decimal("1.5")])
        batch = acsylla.create_batch_logged()
        batch.add_statement(statement)
        with pytest.raises(ValueError, match="this session has legacy_types=False"):
            await session.execute_batch(batch)
