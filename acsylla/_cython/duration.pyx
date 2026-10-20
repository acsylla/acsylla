import calendar
import operator

from datetime import date as datetime_date
from datetime import datetime as datetime_datetime
from datetime import timedelta as datetime_timedelta


cdef inline long long truncated_microseconds(long long nanoseconds):
    """The microseconds of `nanoseconds` cut toward 0, so a duration and its negation have the same size."""
    if nanoseconds < 0:
        return -((-nanoseconds) // 1000)
    return nanoseconds // 1000


cdef object add_duration(object value, long long months, long long days, long long nanoseconds):
    """`value` + the duration as dateutil.relativedelta adds it: the months first, the day moved back to the last one
    of a shorter month, then the days and the nanoseconds cut to microseconds. A date becomes a datetime when there
    are microseconds to add."""
    cdef long long microseconds = truncated_microseconds(nanoseconds)
    if months:
        year, month = divmod(value.year * 12 + value.month - 1 + months, 12)
        month += 1
        if not 1 <= year <= 9999:
            raise OverflowError(f"the year {year} is out of the years 1..9999 of Python")
        value = value.replace(year=year, month=month, day=min(value.day, calendar.monthrange(year, month)[1]))
    if microseconds and not isinstance(value, datetime_datetime):
        value = datetime_datetime.fromordinal(value.toordinal())
    if days or microseconds:
        value = value + datetime_timedelta(days=days, microseconds=microseconds)
    return value


cdef object integral(object value, str name):
    """An int of an int or a float without a fraction."""
    if isinstance(value, float):
        if not value.is_integer():
            raise ValueError(f"A duration has no fraction of a {name}, the value has {name}={value}")
        return int(value)
    return operator.index(value)


cdef class Duration:
    """A duration of CQL: its months, days and nanoseconds.

    CQL keeps the three apart, a month and a day have no fixed length: a day across a change of daylight saving time
    has 23 or 25 hours. The parts that are not 0 have one sign. str() of a Duration is its CQL literal, as
    '1y2mo3d4h5m6s7ms8us9ns'.

    It is added to and subtracted from a date or a datetime as dateutil.relativedelta does it: the months first, the
    day moved back to the last one of a shorter month, then the days and the nanoseconds cut to microseconds.
    to_relativedelta() and from_relativedelta() convert it with dateutil, which acsylla does not depend on.
    """

    def __cinit__(self, months=0, days=0, nanoseconds=0):
        if months is 0 and days is 0 and nanoseconds is 0:
            # Duration() and new_(), that sets the parts of a value of CQL itself
            return
        months = operator.index(months)
        days = operator.index(days)
        nanoseconds = operator.index(nanoseconds)
        if not -2147483648 <= months <= 2147483647 or not -2147483648 <= days <= 2147483647:
            raise ValueError(f"The months and days of a duration are 32 bits in CQL: months={months}, days={days}")
        if not -9223372036854775808 <= nanoseconds <= 9223372036854775807:
            raise ValueError(f"The nanoseconds of a duration are 64 bits in CQL: nanoseconds={nanoseconds}")
        if (months < 0 or days < 0 or nanoseconds < 0) and (months > 0 or days > 0 or nanoseconds > 0):
            raise ValueError(
                "The months, days and nanoseconds of a duration have one sign in CQL: "
                f"months={months}, days={days}, nanoseconds={nanoseconds}"
            )
        self.months = months
        self.days = days
        self.nanoseconds = nanoseconds

    @staticmethod
    cdef Duration new_(int months, int days, long long nanoseconds):
        """A duration of the parts of a value of CQL, as they are."""
        cdef Duration duration = Duration.__new__(Duration)
        duration.months = months
        duration.days = days
        duration.nanoseconds = nanoseconds
        return duration

    def __repr__(self):
        return f"Duration(months={self.months}, days={self.days}, nanoseconds={self.nanoseconds})"

    def __str__(self):
        return duration_literal(self.months, self.days, self.nanoseconds, False)

    def __eq__(self, other):
        if isinstance(other, Duration):
            return (self.months == (<Duration>other).months and self.days == (<Duration>other).days
                    and self.nanoseconds == (<Duration>other).nanoseconds)
        return NotImplemented

    def __ne__(self, other):
        if isinstance(other, Duration):
            return not self == other
        return NotImplemented

    def __hash__(self):
        return hash((Duration, self.months, self.days, self.nanoseconds))

    def __bool__(self):
        return self.months != 0 or self.days != 0 or self.nanoseconds != 0

    def __neg__(self):
        return Duration(-self.months, -self.days, -self.nanoseconds)

    def __pos__(self):
        return self

    def __reduce__(self):
        return Duration, (self.months, self.days, self.nanoseconds)

    def __add__(self, other):
        if isinstance(other, datetime_date):
            return add_duration(other, self.months, self.days, self.nanoseconds)
        return NotImplemented

    def __radd__(self, other):
        if isinstance(other, datetime_date):
            return add_duration(other, self.months, self.days, self.nanoseconds)
        return NotImplemented

    def __rsub__(self, other):
        if isinstance(other, datetime_date):
            return add_duration(other, -(<long long>self.months), -(<long long>self.days), -self.nanoseconds)
        return NotImplemented

    def to_timedelta(self):
        """The timedelta of a duration without months, its nanoseconds cut to microseconds. A ValueError for one with
        months: a month has no fixed length."""
        if self.months:
            raise ValueError(f"A duration of months has no timedelta, a month has no fixed length: {self!r}")
        return datetime_timedelta(days=self.days, microseconds=truncated_microseconds(self.nanoseconds))

    def to_relativedelta(self):
        """The dateutil.relativedelta of the duration, its nanoseconds cut to microseconds. relativedelta keeps the
        hours of more than a day as days, 25h as 1d1h, which CQL does not."""
        try:
            from dateutil.relativedelta import relativedelta
        except ImportError:
            raise ImportError(
                "Duration.to_relativedelta() needs python-dateutil: pip install python-dateutil"
            ) from None
        return relativedelta(months=self.months, days=self.days,
                             microseconds=truncated_microseconds(self.nanoseconds))

    @staticmethod
    def from_relativedelta(value):
        """The Duration of a dateutil.relativedelta of relative parts, a ValueError for one with absolute ones (year,
        month, day, weekday, hour, minute, second, microsecond, leapdays), fractions or parts of two signs."""
        for name in ("year", "month", "day", "weekday", "hour", "minute", "second", "microsecond"):
            if getattr(value, name, None) is not None:
                raise ValueError(f"A duration has no absolute {name}, the value has {name}={getattr(value, name)!r}")
        if getattr(value, "leapdays", 0):
            raise ValueError(f"A duration has no leapdays, the value has leapdays={value.leapdays}")
        months = integral(value.years, "year") * 12 + integral(value.months, "month")
        nanoseconds = (
            ((integral(value.hours, "hour") * 60 + integral(value.minutes, "minute")) * 60
             + integral(value.seconds, "second")) * 1000000000
            + integral(value.microseconds, "microsecond") * 1000
        )
        return Duration(months, integral(value.days, "day"), nanoseconds)
