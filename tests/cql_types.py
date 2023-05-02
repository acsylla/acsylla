from datetime import date
from datetime import datetime
from datetime import time
from datetime import timedelta
from decimal import Decimal
from ipaddress import IPv4Address
from ipaddress import IPv6Address
from uuid import UUID

"""
Format description for `native_types`

key: CQL native type name
    valid: `list` of `tuple` where first element contains valid value
            for this CQL type and second element contains expected returned
            value from driver.
            NOTE: If expected returns values depending on the `returns_native`
            flag, then second element MUST be `tuple` of two elements
            where first element is expected value when `returns_native=True`
            and second element where `returns_native=False`
            Example:
                "duration": {
                    "valid": [("1y", ((12, 0, 0), "1y"))]
                }
    invalid: `list` of `tuple` where first element contains invalid value
            for this CQL type and second element contains expected `Exception`
"""

native_types = {
    "ascii": {
        "valid": [
            ("good ascii string 0123456789", "good ascii string 0123456789"),
            (123, "123"),
            (123.45, "123.45"),
            (date(2022, 12, 28), "2022-12-28"),
        ],
        "invalid": [("bad_äscii_strinng", UnicodeEncodeError)],
    },
    "bigint": {
        "valid": [
            (123.45, 123),
            (-9223372036854775808, -9223372036854775808),
            (9223372036854775807, 9223372036854775807),
            ("-9223372036854775808", -9223372036854775808),
            ("9223372036854775807", 9223372036854775807),
        ],
        "invalid": [
            ("bad_value", ValueError),
            (9223372036854775808, OverflowError),
            (-92233720368000054775808, OverflowError),
            ("9223372036854775808", OverflowError),
        ],
    },
    "blob": {"valid": [(b"good_blob", b"good_blob")], "invalid": [("bad_blob", ValueError)]},
    "boolean": {
        "valid": [(True, True), (False, False), (1, True), (0, False)],
        "invalid": [("bad_boolean", ValueError)],
    },
    "date": {
        "valid": [
            ("0001-02-28", ("0001-02-28", date(1, 2, 28))),
            ("0400-03-01", ("0400-03-01", date(400, 3, 1))),
            ("0400-01-01", ("0400-01-01", date(400, 1, 1))),
            ("1970-01-01", ("1970-01-01", date(1970, 1, 1))),
            (date(500, 1, 1), ("0500-01-01", date(500, 1, 1))),
            ("2022-12-14", ("2022-12-14", date(2022, 12, 14))),
            ("2022-12-14 18:34", ("2022-12-14", date(2022, 12, 14))),
            (datetime(2022, 12, 14, 18, 34, 12), ("2022-12-14", date(2022, 12, 14))),
            ("2022-12-14 18:34+02:00", ("2022-12-14", date(2022, 12, 14))),
            (1671036203.636648, ("2022-12-14", date(2022, 12, 14))),
            (1671036203, ("2022-12-14", date(2022, 12, 14))),
            (-62105616000.0, ("0001-12-14", date(1, 12, 14))),
            (-62105616000, ("0001-12-14", date(1, 12, 14))),
        ],
        "invalid": [("bad_date", ValueError), ("-62105616000", ValueError)],
    },
    "decimal": {
        "valid": [
            (
                Decimal("3.141592653589793115997963468544185161590576171875"),
                (
                    "3.141592653589793115997963468544185161590576171875",
                    Decimal("3.141592653589793115997963468544185161590576171875"),
                ),
            ),
            (
                "3.141592653589793115997963468544185161590576171875",
                (
                    "3.141592653589793115997963468544185161590576171875",
                    Decimal("3.141592653589793115997963468544185161590576171875"),
                ),
            ),
            (3.141592653589793, ("3.141592653589793", Decimal("3.141592653589793"))),
        ],
        "invalid": [("bad", ValueError), ("bad.decimal", ValueError), ("bad.123", ValueError), ("123.bad", ValueError)],
    },
    "double": {
        "valid": [(123.123, 123.123), (123, 123), ("123", 123), ("123.123", 123.123)],
        "invalid": [("bad_double", ValueError)],
    },
    "duration": {
        "valid": [
            ("-1y2mo297d544h5m10s60ms634us3ns", ((-14, -297, -1958710060634003), "-1y2mo297d544h5m10s60ms634us3ns")),
            ("1y", ((12, 0, 0), "1y")),
            ("-1y", ((-12, 0, 0), "-1y")),
            ("-1y2mo", ((-14, 0, 0), "-1y2mo")),
            ("1y2mo54h77", ((14, 0, 194400000000000), "1y2mo54h")),
            (
                timedelta(days=397, hours=1, minutes=3, seconds=2, milliseconds=0, microseconds=999_999),
                ((0, 397, 3782999999000), "397d1h3m2s999ms999us"),
            ),
            ((0, 0, 1), ((0, 0, 1), "1ns")),
        ],
        "invalid": [("bad_duration", ValueError), (123, ValueError)],
    },
    "float": {
        "valid": [(1.0, 1.0), (3, 3.0), (3.14, 3.140000104904175), ("3.14", 3.140000104904175), ("3", 3.0)],
        "invalid": [("bad_float", ValueError)],
    },
    "inet": {
        "valid": [
            ("127.0.0.1", "127.0.0.1"),
            ("::1", "::1"),
            (IPv4Address("127.0.0.1"), "127.0.0.1"),
            (IPv6Address("::1"), "::1"),
        ],
        "invalid": [("bad_ip", ValueError), (1234, ValueError)],
    },
    "int": {
        "valid": [(-2147483648, -2147483648), (2147483647, 2147483647), (123.123, 123), ("123", 123)],
        "invalid": [("bad_int", ValueError), (9223372036854775807, OverflowError), ("123.3", ValueError)],
    },
    "smallint": {
        "valid": [(-32768, -32768), (32767, 32767), (1.1, 1), ("32767", 32767)],
        "invalid": [("bad_smallint", ValueError), (2147483647, OverflowError)],
    },
    "text": {
        "valid": [("abcdé text", "abcdé text"), (121, "121"), (date(1, 2, 3), "0001-02-03")],
        "invalid": [],
    },
    "time": {
        "valid": [
            (86300.999999999, ("23:58:20.999999999", time(23, 58, 20, 999999))),
            ("17:12:32.999999", ("17:12:32.999999000", time(17, 12, 32, 999999))),
            (time(12, 24, 36), ("12:24:36.000000000", time(12, 24, 36))),
            ("12:24", ("12:24:00.000000000", time(12, 24))),
            (datetime(1, 2, 3, 4, 5, 6, 7), ("04:05:06.000007000", time(4, 5, 6, 7))),
            (45299.1234567, ("12:34:59.123456700", time(12, 34, 59, 123456))),
        ],
        "invalid": [("bad_time", ValueError), (167104980116710498011671049, OverflowError), (date.today(), TypeError)],
    },
    "timestamp": {
        "valid": [
            (
                datetime.fromisoformat("2022-12-15 22:23:26.538"),
                ("2022-12-15 22:23:26.538Z", datetime.fromisoformat("2022-12-15 22:23:26.538")),
            ),
            (datetime(1, 1, 1, 0, 0, 0), ("0001-01-01 00:00:00.000Z", datetime(1, 1, 1, 0, 0, 0))),
            (datetime(1, 2, 3, 4, 5, 6), ("0001-02-03 04:05:06.000Z", datetime(1, 2, 3, 4, 5, 6))),
            (datetime(1, 2, 28, 4, 5, 6), ("0001-02-28 04:05:06.000Z", datetime(1, 2, 28, 4, 5, 6))),
            (datetime(400, 4, 2, 4, 5, 6, 7), ("0400-04-02 04:05:06.000Z", datetime(400, 4, 2, 4, 5, 6))),
            (datetime(400, 12, 31, 4, 5, 6, 7), ("0400-12-31 04:05:06.000Z", datetime(400, 12, 31, 4, 5, 6))),
            (datetime(500, 1, 1, 4, 5, 6, 7), ("0500-01-01 04:05:06.000Z", datetime(500, 1, 1, 4, 5, 6))),
            (datetime(500, 2, 28, 4, 5, 6, 7), ("0500-02-28 04:05:06.000Z", datetime(500, 2, 28, 4, 5, 6))),
            (datetime(800, 2, 29, 4, 5, 6, 7), ("0800-02-29 04:05:06.000Z", datetime(800, 2, 29, 4, 5, 6))),
            (datetime(1200, 2, 29, 4, 5, 6, 7), ("1200-02-29 04:05:06.000Z", datetime(1200, 2, 29, 4, 5, 6))),
            (datetime(1200, 1, 1, 0, 0, 0), ("1200-01-01 00:00:00.000Z", datetime(1200, 1, 1, 0, 0, 0))),
            (datetime(1600, 2, 29, 4, 5, 6, 7), ("1600-02-29 04:05:06.000Z", datetime(1600, 2, 29, 4, 5, 6))),
            (datetime(1969, 2, 28, 4, 5, 6, 7), ("1969-02-28 04:05:06.000Z", datetime(1969, 2, 28, 4, 5, 6))),
            (datetime(1969, 3, 1, 4, 5, 6, 7), ("1969-03-01 04:05:06.000Z", datetime(1969, 3, 1, 4, 5, 6))),
            (datetime(1970, 1, 1, 0, 0, 0, 0), ("1970-01-01 00:00:00.000Z", datetime(1970, 1, 1, 0, 0, 0))),
            (datetime(2022, 1, 1, 0, 0, 0, 0), ("2022-01-01 00:00:00.000Z", datetime(2022, 1, 1, 0, 0, 0))),
            (datetime(2400, 3, 1, 4, 5, 6, 7), ("2400-03-01 04:05:06.000Z", datetime(2400, 3, 1, 4, 5, 6))),
            (datetime(9400, 3, 1, 4, 5, 6, 7), ("9400-03-01 04:05:06.000Z", datetime(9400, 3, 1, 4, 5, 6))),
            ("2022-02-12 12:34:23", ("2022-02-12 12:34:23.000Z", datetime(2022, 2, 12, 12, 34, 23))),
            ("2022-02-12 12:34:23+02:00", ("2022-02-12 10:34:23.000Z", datetime.fromisoformat("2022-02-12 10:34:23"))),
            (1671049801.789601, ("2022-12-14 20:30:01.789Z", datetime(2022, 12, 14, 20, 30, 1, 789000))),
            (1671049801, ("2022-12-14 20:30:01.000Z", datetime(2022, 12, 14, 20, 30, 1))),
        ],
        "invalid": [("bad_timestamp", ValueError)],
    },
    "timeuuid": {
        "valid": [
            ("3cd1a00b-7bee-11ed-aff2-510dcc4598b0", "3cd1a00b-7bee-11ed-aff2-510dcc4598b0"),
            (UUID("3cd1a00b-7bee-11ed-aff2-510dcc4598b0"), "3cd1a00b-7bee-11ed-aff2-510dcc4598b0"),
        ],
        "invalid": [("bad_timeuuid", ValueError), (1234, ValueError)],
    },
    "tinyint": {
        "valid": [(127, 127), (-127, -127), ("127", 127), (1.123, 1)],
        "invalid": [
            ("bad_tinyint", ValueError),
            (12345, OverflowError),
            ("12345", OverflowError),
            ("1.123", ValueError),
        ],
    },
    "uuid": {
        "valid": [
            ("3cd1a00b-7bee-11ed-aff2-510dcc4598b0", "3cd1a00b-7bee-11ed-aff2-510dcc4598b0"),
            (UUID("3cd1a00b-7bee-11ed-aff2-510dcc4598b0"), "3cd1a00b-7bee-11ed-aff2-510dcc4598b0"),
        ],
        "invalid": [("bad_timeuuid", ValueError), (1234, ValueError)],
    },
    "varchar": {"valid": [("varchar", "varchar"), (b"varchar", "varchar")], "invalid": []},
    "varint": {
        "valid": [(b"9223372036854775807", b"9223372036854775807")],
        "invalid": [("varint_variant", ValueError), ("1234", ValueError)],
    },
}

collections_types = ["map", "set", "list"]

tuples_types = ["tuple"]

udt_types = ["udt"]


def create_query(types=None):
    types = types or ("udt_nested_type", "udt_type", "udt", "native", "map", "set", "list", "tuple")
    udt = "CREATE TYPE test_{name} ({types})"
    table = "CREATE TABLE test_{name} (id int PRIMARY KEY, {types})"

    for t in types:
        data_types = sorted(set(native_types))
        if t in ("udt_type", "udt_nested_type"):
            t_types = ", ".join([f"value_{k} {k}" for k in data_types])
            if t == "udt_type":
                t_types += f", value_{t} frozen<test_udt_nested_type>"
            yield udt.format(**dict(name=t, types=t_types))
        elif t in ("native",):
            t_types = ", ".join([f"value_{k} {k}" for k in data_types])
            yield table.format(**dict(name=t, types=t_types))
        elif t in ("tuple",):
            t_types = ", ".join([f"value_{k} {t}<{k}, {k}>" for k in data_types])
            yield table.format(**dict(name=t, types=t_types))
        elif t in ("list",):
            t_types = ", ".join([f"value_{k} {t}<{k}>" for k in data_types])
            yield table.format(**dict(name=t, types=t_types))
        elif t in ("set",):
            # set doesn't support duration type
            data_types = set(data_types) - {"duration"}
            t_types = ", ".join([f"value_{k} {t}<{k}>" for k in sorted(data_types)])
            yield table.format(**dict(name=t, types=t_types))
        elif t in ("map",):
            # map doesn't support duration type as key
            data_types = set(data_types) - {"duration"}
            t_types = ", ".join([f"value_{k} {t}<{k}, {k}>" for k in sorted(data_types)])
            yield table.format(**dict(name=t, types=t_types))
        elif t in ("udt",):
            t_types = ", ".join([f"value_{k} frozen<test_udt_type>" for k in data_types])
            yield table.format(**dict(name=t, types=t_types))


def insert_query(query_type=None, value_type=None):
    if query_type not in ("native", "map", "set", "list", "tuple", "udt"):
        raise ValueError(f'Unknown data_type: "{query_type}"')
    query = "INSERT INTO test_{name} (id, {types}) VALUES ({values})"
    data_types = set(native_types)
    if query_type in ("map", "set"):
        data_types -= {"duration"}

    if value_type is None:
        return query.format(
            name=query_type,
            types=",".join([f"value_{k}" for k in sorted(data_types)]),
            values=("?," * (len(data_types) + 1))[:-1],
        )
    return query.format(name=query_type, types=f"value_{value_type}", values="?,?")
