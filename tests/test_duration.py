"""acsylla.Duration, without a server."""

from acsylla import Duration
from datetime import date
from datetime import datetime
from datetime import timedelta
from datetime import timezone

import copy
import pickle
import pytest

HOUR = 3600 * 10**9


@pytest.fixture(scope="class")
def cluster():
    # No server: the session and cluster of conftest are not needed
    return None


@pytest.fixture(scope="class")
def session():
    return None


class TestDuration:
    def test_parts(self):
        value = Duration(14, 3, 5)
        assert (value.months, value.days, value.nanoseconds) == (14, 3, 5)
        assert Duration(days=2) == Duration(0, 2, 0)
        assert (Duration().months, Duration().days, Duration().nanoseconds) == (0, 0, 0)

    def test_one_sign(self):
        assert Duration(-1, -2, -3).days == -2
        assert Duration(0, 0, -1).nanoseconds == -1
        for months, days, nanoseconds in ((1, -1, 0), (-1, 0, 1), (0, 1, -1)):
            with pytest.raises(ValueError, match="one sign"):
                Duration(months, days, nanoseconds)

    def test_ranges(self):
        assert Duration(-(2**31), -(2**31), -(2**63)).months == -(2**31)
        assert Duration(2**31 - 1, 2**31 - 1, 2**63 - 1).nanoseconds == 2**63 - 1
        with pytest.raises(ValueError, match="32 bits"):
            Duration(2**31)
        with pytest.raises(ValueError, match="32 bits"):
            Duration(days=-(2**31) - 1)
        with pytest.raises(ValueError, match="64 bits"):
            Duration(nanoseconds=2**63)

    def test_ints_only(self):
        for value in (1.5, "1", None):
            with pytest.raises(TypeError):
                Duration(value)

    def test_immutable(self):
        value = Duration(1)
        with pytest.raises(AttributeError):
            value.months = 2

    def test_str(self):
        assert str(Duration(14, 3, 14706007008009)) == "1y2mo3d4h5m6s7ms8us9ns"
        assert str(Duration(-14, -3, -14706007008009)) == "-1y2mo3d4h5m6s7ms8us9ns"
        assert str(Duration()) == "0s"
        assert str(Duration(days=-1)) == "-1d"
        # CQL keeps the hours of more than a day apart from the days
        assert str(Duration(nanoseconds=25 * HOUR)) == "25h"
        assert str(Duration(-(2**31), -(2**31), -(2**63))) == "-178956970y8mo2147483648d2562047h47m16s854ms775us808ns"

    def test_repr(self):
        assert repr(Duration(14, 3, 5)) == "Duration(months=14, days=3, nanoseconds=5)"

    def test_eq_hash(self):
        assert Duration(1, 2, 3) == Duration(1, 2, 3)
        assert Duration(1, 2, 3) != Duration(1, 2, 4)
        assert hash(Duration(1, 2, 3)) == hash(Duration(1, 2, 3))
        assert Duration(1, 2, 3) != (1, 2, 3)
        assert {Duration(1, 2, 3): 1}[Duration(1, 2, 3)] == 1
        with pytest.raises(TypeError):
            Duration(1) < Duration(2)

    def test_bool_neg(self):
        assert not Duration()
        assert Duration(nanoseconds=1)
        assert -Duration(1, 2, 3) == Duration(-1, -2, -3)
        value = Duration(1)
        assert +value is value

    def test_pickle_copy(self):
        value = Duration(-14, -3, -5)
        assert pickle.loads(pickle.dumps(value)) == value
        assert copy.copy(value) == value and copy.deepcopy(value) == value

    def test_to_timedelta(self):
        assert Duration(0, 3, 4 * HOUR + 1500).to_timedelta() == timedelta(days=3, hours=4, microseconds=1)
        # The nanoseconds are cut toward 0, a negative duration has the size of its negation
        assert Duration(0, 0, -1500).to_timedelta() == timedelta(microseconds=-1)
        with pytest.raises(ValueError, match="no fixed length"):
            Duration(1).to_timedelta()

    def test_add_months(self):
        # The day is moved back to the last one of a shorter month
        assert date(2024, 1, 31) + Duration(1) == date(2024, 2, 29)
        assert date(2023, 1, 31) + Duration(1) == date(2023, 2, 28)
        assert date(2024, 3, 31) - Duration(1) == date(2024, 2, 29)
        assert Duration(12) + date(2024, 2, 29) == date(2025, 2, 28)
        assert date(2024, 2, 29) + Duration(-12) == date(2023, 2, 28)

    def test_add_days_and_time(self):
        assert datetime(2024, 1, 31, 12) + Duration(1, 1) == datetime(2024, 3, 1, 12)
        assert date(2024, 6, 15) + Duration(days=1) == date(2024, 6, 16)
        # A date with a time to add becomes a datetime
        assert date(2024, 6, 15) + Duration(nanoseconds=HOUR) == datetime(2024, 6, 15, 1)
        moment = datetime(2024, 6, 15, 12, 30, tzinfo=timezone.utc)
        assert moment + Duration(0, 0, 25 * HOUR) == datetime(2024, 6, 16, 13, 30, tzinfo=timezone.utc)
        assert moment - Duration(0, 1, HOUR) == datetime(2024, 6, 14, 11, 30, tzinfo=timezone.utc)

    def test_add_errors(self):
        with pytest.raises(OverflowError):
            date(9999, 12, 1) + Duration(1)
        with pytest.raises(TypeError):
            Duration(1) + 1
        with pytest.raises(TypeError):
            Duration(1) - date(2024, 1, 1)


class TestDurationRelativedelta:
    @pytest.fixture(autouse=True)
    def dateutil(self):
        return pytest.importorskip("dateutil.relativedelta")

    @pytest.mark.parametrize(
        "value",
        [
            Duration(1),
            Duration(-1),
            Duration(14, 3, 4 * HOUR + 5 * 60 * 10**9 + 6007008000),
            Duration(0, 0, 25 * HOUR),
            Duration(-13, -40, -HOUR),
            Duration(0, 0, 1500),
        ],
    )
    @pytest.mark.parametrize(
        "moment",
        [
            date(2024, 1, 31),
            date(2023, 12, 31),
            datetime(2024, 2, 29, 23, 59, 59, 999999),
            datetime(2024, 3, 31, 0, 30),
        ],
    )
    def test_same_arithmetic(self, value, moment):
        assert moment + value == moment + value.to_relativedelta()
        assert moment - value == moment - value.to_relativedelta()

    def test_to_relativedelta(self, dateutil):
        assert Duration(14, 3, HOUR + 1500).to_relativedelta() == dateutil.relativedelta(
            years=1, months=2, days=3, hours=1, microseconds=1
        )

    def test_from_relativedelta(self, dateutil):
        relativedelta = dateutil.relativedelta
        assert Duration.from_relativedelta(
            relativedelta(years=1, months=2, days=3, hours=4, minutes=5, seconds=6, microseconds=7008)
        ) == Duration(14, 3, 14706007008000)
        assert Duration.from_relativedelta(relativedelta(weeks=2)) == Duration(days=14)
        assert Duration.from_relativedelta(relativedelta(months=-1, days=-1)) == Duration(-1, -1)
        # relativedelta keeps 25 hours as 1 day and 1 hour, CQL does not
        assert Duration.from_relativedelta(Duration(nanoseconds=25 * HOUR).to_relativedelta()) == Duration(0, 1, HOUR)

    @pytest.mark.parametrize(
        "kwargs, match",
        [
            ({"day": 31}, "absolute day"),
            ({"months": 1, "hour": 3}, "absolute hour"),
            ({"leapdays": 1}, "leapdays"),
            ({"days": 1.5}, "fraction"),
            ({"months": 1, "days": -1}, "one sign"),
        ],
    )
    def test_from_relativedelta_errors(self, dateutil, kwargs, match):
        with pytest.raises(ValueError, match=match):
            Duration.from_relativedelta(dateutil.relativedelta(**kwargs))

    def test_from_relativedelta_weekday(self, dateutil):
        with pytest.raises(ValueError, match="absolute weekday"):
            Duration.from_relativedelta(dateutil.relativedelta(weekday=dateutil.MO))
