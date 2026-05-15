cdef extern from "utils.cpp":
    int days_from_civil(int y, unsigned m, unsigned d) nogil

from cpython.datetime cimport date
from cpython.datetime cimport datetime
from cpython.datetime cimport get_utc
from cpython.datetime cimport time
from cpython.datetime cimport timedelta
from libc.time cimport time_t

from uuid import UUID

import_datetime()


cdef inline (cass_int32_t, cass_int32_t, cass_int64_t) _parse_duration_str(str s) except *:
    """Parse Cassandra duration string like '1y2mo3w4d5h6m7s8ms9us10ns'.

    Matches legacy regex-based behaviour: scans the string for
    <digits><unit> pairs and silently skips anything that isn't a valid pair
    (orphan trailing digits, whitespace, etc.). Raises ValueError only if no
    valid pair is found.  A leading '-' negates the whole duration.
    """
    cdef bytes b = s.encode('utf-8')
    cdef Py_ssize_t n = len(b)
    cdef Py_ssize_t i = 0
    cdef cass_int32_t months = 0
    cdef cass_int32_t days = 0
    cdef cass_int64_t nanos = 0
    cdef bint negative = False
    cdef bint had_any = False
    cdef cass_int64_t value
    cdef int c, c2
    cdef int unit_len

    if n == 0:
        raise ValueError(f'Unknown duration format for value: "{s}"')

    if b[0] == 0x2d:  # '-'
        negative = True

    while i < n:
        # skip to next digit
        while i < n and not (0x30 <= b[i] <= 0x39):
            i += 1
        if i >= n:
            break

        # parse digits into C int
        value = 0
        while i < n and 0x30 <= b[i] <= 0x39:
            value = value * 10 + (b[i] - 0x30)
            i += 1
        if i >= n:
            break

        c = b[i]
        unit_len = 0

        # µ (UTF-8: 0xc2 0xb5) followed by s/S → microseconds
        if c == 0xc2 and i + 1 < n and b[i + 1] == 0xb5:
            if i + 2 < n and (b[i + 2] == 0x73 or b[i + 2] == 0x53):
                nanos += value * 1000
                unit_len = 3
        else:
            # ASCII unit, case-insensitive
            if 0x41 <= c <= 0x5A:
                c += 32
            c2 = 0
            if i + 1 < n:
                c2 = b[i + 1]
                if 0x41 <= c2 <= 0x5A:
                    c2 += 32

            if c == 0x79:                                  # 'y'
                months += value * 12
                unit_len = 1
            elif c == 0x6d and c2 == 0x6f:                 # 'mo'
                months += value
                unit_len = 2
            elif c == 0x77:                                # 'w'
                days += value * 7
                unit_len = 1
            elif c == 0x64:                                # 'd'
                days += value
                unit_len = 1
            elif c == 0x68:                                # 'h'
                nanos += value * <cass_int64_t>3600000000000
                unit_len = 1
            elif c == 0x6d and c2 == 0x73:                 # 'ms'
                nanos += value * 1000000
                unit_len = 2
            elif c == 0x75 and c2 == 0x73:                 # 'us'
                nanos += value * 1000
                unit_len = 2
            elif c == 0x6e and c2 == 0x73:                 # 'ns'
                nanos += value
                unit_len = 2
            elif c == 0x6d:                                # 'm' (minutes)
                nanos += value * <cass_int64_t>60000000000
                unit_len = 1
            elif c == 0x73:                                # 's'
                nanos += value * <cass_int64_t>1000000000
                unit_len = 1

        if unit_len > 0:
            had_any = True
            i += unit_len
        else:
            i += 1  # unknown char, skip and keep scanning

    if not had_any:
        raise ValueError(f'Unknown duration format for value: "{s}"')

    if negative:
        return -months, -days, -nanos
    return months, days, nanos


cdef inline as_bytes(object value, str encoding='utf-8'):
    if isinstance(value, bytes):
        return value
    return value.encode(encoding) if isinstance(value, str) else str(value).encode(encoding)


cdef inline as_blob(object value):
    if isinstance(value, bytes):
        return value
    raise ValueError(f'Value "{value}" is not bytes.')


cdef inline cass_bool_t as_bool(object value) except *:
    if value in (True, False, 0, 1):
        return cass_true if value else cass_false
    raise ValueError(f'Value "{value}" is not boolean.')


cdef inline (cass_byte_t*, cass_int32_t) as_cass_decimal(object value) except *:
    cdef str s
    cdef bytes b
    cdef Py_ssize_t n, i, dot_pos, digits_start
    cdef cass_int32_t scale

    if isinstance(value, str):
        s = <str>value
    else:
        s = str(value)

    b = s.encode('ascii')
    n = len(b)
    if n == 0:
        raise ValueError(f'Bad value for decimal type: "{value}"')

    digits_start = 1 if (b[0] == 0x2b or b[0] == 0x2d) else 0
    if digits_start >= n:
        raise ValueError(f'Bad value for decimal type: "{value}"')

    dot_pos = -1
    i = digits_start
    while i < n:
        if b[i] == 0x2e:  # '.'
            if dot_pos != -1:
                raise ValueError(f'Bad value for decimal type: "{value}"')
            dot_pos = i
        elif not (0x30 <= b[i] <= 0x39):
            raise ValueError(f'Bad value for decimal type: "{value}"')
        i += 1

    if dot_pos == -1:
        scale = 0
    else:
        if dot_pos == digits_start or dot_pos == n - 1:
            raise ValueError(f'Bad value for decimal type: "{value}"')
        scale = <cass_int32_t>(n - 1 - dot_pos)

    return b, scale


cdef inline CassUuid as_cass_uuid(object value) except *:
    cdef CassUuid cass_uuid
    cdef CassError error
    cdef object int_val
    cdef bytes b
    cdef cass_uint64_t uuid_hi, uuid_lo
    cdef cass_uint64_t time_low, time_mid, time_hi_and_version

    if isinstance(value, UUID):
        int_val = value.int
        uuid_hi = <cass_uint64_t>((int_val >> 64) & 0xFFFFFFFFFFFFFFFF)
        uuid_lo = <cass_uint64_t>(int_val & 0xFFFFFFFFFFFFFFFF)

        # Repack top half into CassUuid.time_and_version layout:
        #   bits 0-31  = time_low
        #   bits 32-47 = time_mid
        #   bits 48-63 = time_hi_and_version
        time_low = (uuid_hi >> 32) & 0xFFFFFFFF
        time_mid = (uuid_hi >> 16) & 0xFFFF
        time_hi_and_version = uuid_hi & 0xFFFF
        cass_uuid.time_and_version = (time_hi_and_version << 48) | (time_mid << 32) | time_low
        cass_uuid.clock_seq_and_node = uuid_lo
        return cass_uuid

    if isinstance(value, str):
        b = (<str>value).encode('ascii')
    elif isinstance(value, bytes):
        b = value
    else:
        b = str(value).encode('ascii')

    error = cass_uuid_from_string(b, &cass_uuid)
    if error:
        raise ValueError(f'Bad UUID value: "{value}"')
    return cass_uuid


cdef inline CassInet as_cass_inet(object value) except *:
    cdef CassInet cass_inet
    cdef CassError error
    error = cass_inet_from_string(as_bytes(value), &cass_inet)
    if error:
        raise ValueError(f'Bad IP address value: "{value}"')
    return cass_inet


cdef inline time_t _timegm(int year, unsigned month, unsigned day, unsigned hour, unsigned minute, unsigned second) except * nogil:
    cdef int days_since_epoch = days_from_civil(year, month, day)
    return 60 * (60 * (24L * days_since_epoch + hour) + minute) + second


cdef inline int _try_parse_iso_date_days(str s, int* out) except -1:
    """Parse 'YYYY-MM-DD' (optionally followed by T/space and time) to days
    since epoch. Returns 1 on success, 0 on format mismatch.
    """
    cdef bytes b
    try:
        b = s.encode('ascii')
    except UnicodeEncodeError:
        return 0
    cdef Py_ssize_t n = len(b)
    cdef int year, month, day

    if n < 10:
        return 0
    if not (0x30 <= b[0] <= 0x39 and 0x30 <= b[1] <= 0x39
            and 0x30 <= b[2] <= 0x39 and 0x30 <= b[3] <= 0x39):
        return 0
    if b[4] != 0x2d or b[7] != 0x2d:
        return 0
    if not (0x30 <= b[5] <= 0x39 and 0x30 <= b[6] <= 0x39
            and 0x30 <= b[8] <= 0x39 and 0x30 <= b[9] <= 0x39):
        return 0
    if n > 10 and b[10] != 0x54 and b[10] != 0x74 and b[10] != 0x20:
        return 0

    year = (b[0] - 0x30) * 1000 + (b[1] - 0x30) * 100 + (b[2] - 0x30) * 10 + (b[3] - 0x30)
    month = (b[5] - 0x30) * 10 + (b[6] - 0x30)
    day = (b[8] - 0x30) * 10 + (b[9] - 0x30)

    out[0] = days_from_civil(year, month, day)
    return 1


cdef inline cass_uint32_t as_cass_date(object value) except *:
    cdef cass_uint32_t cass_date
    cdef time_t epoch_secs
    cdef int days_out

    if isinstance(value, str):
        if _try_parse_iso_date_days(value, &days_out) == 1:
            return <cass_uint32_t>(days_out + 2147483648)
        value = datetime.fromisoformat(value)

    if isinstance(value, (date, datetime)):
        return <cass_uint32_t>(days_from_civil(value.year, value.month, value.day) + 2147483648)

    epoch_secs = value
    cass_date = cass_date_from_epoch(epoch_secs)
    return cass_date


cdef inline int _try_parse_iso_time_ns(str s, cass_int64_t* out) except -1:
    """Parse 'HH:MM[:SS[.fraction]][Z|±HH[:]MM]' to nanoseconds since midnight."""
    cdef bytes b
    try:
        b = s.encode('ascii')
    except UnicodeEncodeError:
        return 0
    cdef Py_ssize_t n = len(b)
    cdef Py_ssize_t i = 5
    cdef int hour = 0, minute = 0, second = 0, frac_digits = 0
    cdef cass_int64_t nanos_frac = 0
    cdef int tz_sign = 0, tz_hour = 0, tz_min = 0
    cdef cass_int64_t nanos

    if n < 5:
        return 0
    if not (0x30 <= b[0] <= 0x39 and 0x30 <= b[1] <= 0x39):
        return 0
    if b[2] != 0x3a:
        return 0
    if not (0x30 <= b[3] <= 0x39 and 0x30 <= b[4] <= 0x39):
        return 0

    hour = (b[0] - 0x30) * 10 + (b[1] - 0x30)
    minute = (b[3] - 0x30) * 10 + (b[4] - 0x30)

    if i < n and b[i] == 0x3a:
        i += 1
        if i + 1 >= n or not (0x30 <= b[i] <= 0x39 and 0x30 <= b[i + 1] <= 0x39):
            return 0
        second = (b[i] - 0x30) * 10 + (b[i + 1] - 0x30)
        i += 2

        if i < n and b[i] == 0x2e:
            i += 1
            while i < n and 0x30 <= b[i] <= 0x39:
                if frac_digits < 9:
                    nanos_frac = nanos_frac * 10 + (b[i] - 0x30)
                    frac_digits += 1
                i += 1
            if frac_digits == 0:
                return 0
            while frac_digits < 9:
                nanos_frac *= 10
                frac_digits += 1

    if i < n:
        if b[i] == 0x5a or b[i] == 0x7a:
            i += 1
        elif b[i] == 0x2b or b[i] == 0x2d:
            tz_sign = 1 if b[i] == 0x2b else -1
            i += 1
            if i + 1 >= n or not (0x30 <= b[i] <= 0x39 and 0x30 <= b[i + 1] <= 0x39):
                return 0
            tz_hour = (b[i] - 0x30) * 10 + (b[i + 1] - 0x30)
            i += 2
            if i < n and b[i] == 0x3a:
                i += 1
            if i + 1 <= n and i + 1 < n and 0x30 <= b[i] <= 0x39 and 0x30 <= b[i + 1] <= 0x39:
                tz_min = (b[i] - 0x30) * 10 + (b[i + 1] - 0x30)
                i += 2
        else:
            return 0

    if i != n:
        return 0

    nanos = (<cass_int64_t>hour * 3600 + <cass_int64_t>minute * 60 + second) * 1000000000 + nanos_frac
    if tz_sign != 0:
        nanos -= <cass_int64_t>tz_sign * (tz_hour * 3600 + tz_min * 60) * 1000000000

    out[0] = nanos
    return 1


cdef inline cass_int64_t _time_to_ns(object value):
    cdef cass_int64_t t = (<cass_int64_t>value.hour * 3600
                           + <cass_int64_t>value.minute * 60
                           + value.second) * 1_000_000_000
    t += <cass_int64_t>value.microsecond * 1_000
    cdef object offset
    if value.tzinfo is not None:
        offset = value.utcoffset()
        if offset is not None:
            t -= <cass_int64_t>(offset.total_seconds() * 1_000_000_000)
    return t


cdef inline cass_int64_t as_cass_time(object value) except *:
    cdef cass_int64_t out_val

    if isinstance(value, str):
        if _try_parse_iso_time_ns(value, &out_val) == 1:
            return out_val
        value = time.fromisoformat(value)

    if isinstance(value, (time, datetime)):
        return _time_to_ns(value)

    return <cass_int64_t>(value * 1_000_000_000)


cdef inline int _try_parse_iso_timestamp_ms(str s, cass_int64_t* out) except -1:
    """Fast path ISO 8601 parser. Returns 1 on success, 0 on format mismatch.

    Treats naive strings (no timezone) as UTC to match the existing behaviour
    where `datetime.fromisoformat` + `.replace(tzinfo=get_utc())` was used.
    """
    cdef bytes b
    try:
        b = s.encode('ascii')
    except UnicodeEncodeError:
        return 0
    cdef Py_ssize_t n = len(b)
    cdef Py_ssize_t i
    cdef int year, month, day
    cdef int hour = 0, minute = 0, second = 0, microsecond = 0
    cdef int frac_digits
    cdef int tz_sign = 0
    cdef int tz_hour = 0, tz_min = 0
    cdef int days
    cdef cass_int64_t ms

    if n < 10:
        return 0
    if not (0x30 <= b[0] <= 0x39 and 0x30 <= b[1] <= 0x39
            and 0x30 <= b[2] <= 0x39 and 0x30 <= b[3] <= 0x39):
        return 0
    if b[4] != 0x2d or b[7] != 0x2d:  # '-'
        return 0
    if not (0x30 <= b[5] <= 0x39 and 0x30 <= b[6] <= 0x39
            and 0x30 <= b[8] <= 0x39 and 0x30 <= b[9] <= 0x39):
        return 0

    year = (b[0] - 0x30) * 1000 + (b[1] - 0x30) * 100 + (b[2] - 0x30) * 10 + (b[3] - 0x30)
    month = (b[5] - 0x30) * 10 + (b[6] - 0x30)
    day = (b[8] - 0x30) * 10 + (b[9] - 0x30)

    i = 10

    if i < n:
        # Date/time separator: 'T', 't' or ' '
        if b[i] != 0x54 and b[i] != 0x74 and b[i] != 0x20:
            return 0
        i += 1
        if i + 1 >= n or not (0x30 <= b[i] <= 0x39 and 0x30 <= b[i + 1] <= 0x39):
            return 0
        hour = (b[i] - 0x30) * 10 + (b[i + 1] - 0x30)
        i += 2

        if i < n and b[i] == 0x3a:  # ':'
            i += 1
            if i + 1 >= n or not (0x30 <= b[i] <= 0x39 and 0x30 <= b[i + 1] <= 0x39):
                return 0
            minute = (b[i] - 0x30) * 10 + (b[i + 1] - 0x30)
            i += 2

            if i < n and b[i] == 0x3a:
                i += 1
                if i + 1 >= n or not (0x30 <= b[i] <= 0x39 and 0x30 <= b[i + 1] <= 0x39):
                    return 0
                second = (b[i] - 0x30) * 10 + (b[i + 1] - 0x30)
                i += 2

                if i < n and b[i] == 0x2e:  # '.'
                    i += 1
                    frac_digits = 0
                    microsecond = 0
                    while i < n and 0x30 <= b[i] <= 0x39:
                        if frac_digits < 6:
                            microsecond = microsecond * 10 + (b[i] - 0x30)
                            frac_digits += 1
                        i += 1
                    if frac_digits == 0:
                        return 0
                    while frac_digits < 6:
                        microsecond *= 10
                        frac_digits += 1

        # Optional timezone
        if i < n:
            if b[i] == 0x5a or b[i] == 0x7a:  # 'Z' / 'z'
                i += 1
            elif b[i] == 0x2b or b[i] == 0x2d:  # '+' / '-'
                tz_sign = 1 if b[i] == 0x2b else -1
                i += 1
                if i + 1 >= n or not (0x30 <= b[i] <= 0x39 and 0x30 <= b[i + 1] <= 0x39):
                    return 0
                tz_hour = (b[i] - 0x30) * 10 + (b[i + 1] - 0x30)
                i += 2
                if i < n and b[i] == 0x3a:
                    i += 1
                if i + 1 <= n and i + 1 < n and 0x30 <= b[i] <= 0x39 and 0x30 <= b[i + 1] <= 0x39:
                    tz_min = (b[i] - 0x30) * 10 + (b[i + 1] - 0x30)
                    i += 2
            else:
                return 0

        if i != n:
            return 0

    days = days_from_civil(year, month, day)
    ms = (<cass_int64_t>days * 86400000
          + <cass_int64_t>hour * 3600000
          + <cass_int64_t>minute * 60000
          + <cass_int64_t>second * 1000
          + <cass_int64_t>(microsecond // 1000))

    if tz_sign != 0:
        ms -= <cass_int64_t>tz_sign * (tz_hour * 3600000 + tz_min * 60000)

    out[0] = ms
    return 1


cdef inline cass_int64_t _datetime_to_ms(datetime dt):
    cdef int year = dt.year
    cdef int month = dt.month
    cdef int day = dt.day
    cdef int hour = dt.hour
    cdef int minute = dt.minute
    cdef int second = dt.second
    cdef int microsecond = dt.microsecond
    cdef int days = days_from_civil(year, month, day)
    cdef cass_int64_t ms = (<cass_int64_t>days * 86400000
                            + <cass_int64_t>hour * 3600000
                            + <cass_int64_t>minute * 60000
                            + <cass_int64_t>second * 1000
                            + <cass_int64_t>(microsecond // 1000))
    cdef object offset
    if dt.tzinfo is not None:
        offset = dt.utcoffset()
        if offset is not None:
            ms -= <cass_int64_t>(offset.total_seconds() * 1000)
    return ms


cdef inline cass_int64_t as_cass_timestamp(object value) except *:
    cdef datetime dt
    cdef cass_int64_t out

    if isinstance(value, str):
        if _try_parse_iso_timestamp_ms(value, &out) == 1:
            return out
        dt = datetime.fromisoformat(value)
    elif isinstance(value, datetime):
        dt = value
    else:
        return <cass_int64_t>(value * 1_000)

    return _datetime_to_ms(dt)


cdef inline (cass_int32_t, cass_int32_t, cass_int64_t) as_cass_duration(object value) except *:
    cdef cass_int32_t months = 0
    cdef cass_int32_t days = 0
    cdef cass_int64_t nanos = 0

    if isinstance(value, tuple) and len(value) == 3:
        months, days, nanos = value
    elif isinstance(value, str):
        months, days, nanos = _parse_duration_str(value)
    elif isinstance(value, timedelta):
        days = value.days
        nanos = value.seconds * 1000 * 1000 * 1000 + value.microseconds * 1000
    else:
        raise ValueError(f'Unknown duration format for value: "{value}"')

    return months, days, nanos


# CASS_VALUE_TYPE_MAP, CASS_VALUE_TYPE_SET, CASS_VALUE_TYPE_LIST
cdef inline void bind_collection_by_value_type(CassCollection* collection, object value, const CassDataType* cass_data_type, CassValueType cass_value_type) except *:
    cdef CassError error = CASS_OK

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise_if_error(CASS_ERROR_LIB_INVALID_VALUE_TYPE, f'Unknown type for collection value "{value}"'.encode())
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_collection_append_bool(collection, as_bool(value))
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_collection_append_int8(collection, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_collection_append_int16(collection, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_collection_append_int32(collection, int(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_collection_append_int64(collection, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_collection_append_float(collection, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_collection_append_double(collection, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_collection_append_string(collection, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_collection_append_string(collection, as_bytes(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_collection_append_bytes(collection, as_blob(value), len(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = as_cass_decimal(value)
        error = cass_collection_append_decimal(collection, value, len(value), scale)
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_collection_append_uuid(collection, as_cass_uuid(value))
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_collection_append_inet(collection, as_cass_inet(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_collection_append_int64(collection, as_cass_timestamp(value))
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_collection_append_uint32(collection, as_cass_date(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_collection_append_int64(collection, as_cass_time(value))
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = as_cass_duration(value)
        error = cass_collection_append_duration(collection, month, days, nanos)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        nested_collection = get_collection(value, cass_data_type)
        error = cass_collection_append_collection(collection, nested_collection)
        cass_collection_free(nested_collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type)
        error = cass_collection_append_tuple(collection, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        user_type = get_udt(value, cass_data_type)
        error = cass_collection_append_user_type(collection, user_type)
        cass_user_type_free(user_type)

    if error:
        raise_if_error(error)


cdef inline CassCollection* get_collection(object value, const CassDataType* cass_data_type) except *:
    cdef CassCollection* collection = NULL
    cdef CassError error
    cdef const CassDataType* sub_data_type
    cdef CassValueType sub_value_type

    collection = cass_collection_new_from_data_type(cass_data_type, len(value))

    if collection == NULL:
        raise ValueError(f'Unable to bind collection with value {value}')

    collection_type = cass_data_type_type(cass_data_type)

    if collection_type == CASS_VALUE_TYPE_MAP:
        if isinstance(value, dict):
            value = value.items()
        for k, v in value:
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, 0)
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_collection_by_value_type(collection, k, sub_data_type, sub_value_type)
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, 1)
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_collection_by_value_type(collection, v, sub_data_type, sub_value_type)
    else:
        sub_data_type = cass_data_type_sub_data_type(cass_data_type, 0)
        sub_value_type = cass_data_type_type(sub_data_type)
        for i, v in enumerate(value):
            bind_collection_by_value_type(collection, v, sub_data_type, sub_value_type)

    return collection


cdef inline CassError bind_collection(CassStatement* statement, int index, object value, const CassDataType* cass_data_type) except *:
    cdef CassCollection* collection
    cdef CassError error
    collection = get_collection(value, cass_data_type)
    error = cass_statement_bind_collection(statement, index, collection)
    cass_collection_free(collection)
    return error

cdef inline  CassError bind_collection_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type) except *:
    cdef CassCollection* collection
    cdef CassError error
    collection = get_collection(value, cass_data_type)
    error = cass_statement_bind_collection_by_name(statement, name, collection)
    cass_collection_free(collection)
    return error

# CASS_VALUE_TYPE_TUPLE
cdef inline void bind_tuple_by_value_type(CassTuple* cass_tuple, size_t index, object value, const CassDataType* cass_data_type, CassValueType cass_value_type) except *:
    cdef CassError error = CASS_OK

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise_if_error(CASS_ERROR_LIB_INVALID_VALUE_TYPE, f'Unknown type for Tuple index {index} value "{value}"'.encode())
    elif value is None:
        error = cass_tuple_set_null(cass_tuple, index)
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_tuple_set_bool(cass_tuple, index, as_bool(value))
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_tuple_set_int8(cass_tuple, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_tuple_set_int16(cass_tuple, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_tuple_set_int32(cass_tuple, index, int(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_tuple_set_int64(cass_tuple, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_tuple_set_float(cass_tuple, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_tuple_set_double(cass_tuple, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_tuple_set_string(cass_tuple, index, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_tuple_set_string(cass_tuple, index, as_bytes(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_tuple_set_bytes(cass_tuple, index, as_blob(value), len(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = as_cass_decimal(value)
        error = cass_tuple_set_decimal(cass_tuple, index, value, len(value), scale)
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_tuple_set_uuid(cass_tuple, index, as_cass_uuid(value))
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_tuple_set_inet(cass_tuple, index, as_cass_inet(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_tuple_set_int64(cass_tuple, index, as_cass_timestamp(value))
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_tuple_set_uint32(cass_tuple, index, as_cass_date(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_tuple_set_int64(cass_tuple, index, as_cass_time(value))
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = as_cass_duration(value)
        error = cass_tuple_set_duration(cass_tuple, index, month, days, nanos)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        collection = get_collection(value, cass_data_type)
        error = cass_tuple_set_collection(cass_tuple, index, collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        nested_tuple = get_tuple(value, cass_data_type)
        error = cass_tuple_set_tuple(cass_tuple, index, nested_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        user_type = get_udt(value, cass_data_type)
        error = cass_tuple_set_user_type(cass_tuple, index, user_type)

    if error:
        raise_if_error(error)


cdef inline CassTuple* get_tuple(object value, const CassDataType* cass_data_type) except *:
    cdef CassTuple * cass_tuple = NULL
    cdef CassError error
    cdef size_t type_count
    cdef size_t tuple_len = len(value)

    type_count = cass_data_type_sub_type_count(cass_data_type)
    if tuple_len > type_count:
        raise ValueError(
            f'Wrong tuple size (must be {type_count}) for value {value}')

    cass_tuple = cass_tuple_new(tuple_len)

    for i, v in enumerate(value):
        sub_data_type = cass_data_type_sub_data_type(cass_data_type, i)
        if sub_data_type == NULL:
            raise_if_error(CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS, f'Unable to bind Tuple index {i}'.encode())
        sub_value_type = cass_data_type_type(sub_data_type)
        bind_tuple_by_value_type(cass_tuple, i, v, sub_data_type, sub_value_type)

    return cass_tuple


cdef inline bind_tuple(CassStatement* statement, size_t index, object value, const CassDataType* cass_data_type):
    cdef CassError error
    cass_tuple = get_tuple(value, cass_data_type)
    error = cass_statement_bind_tuple(statement, index, cass_tuple)
    cass_tuple_free(cass_tuple)
    return error

cdef inline bind_tuple_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type):
    cdef CassError error
    cass_tuple = get_tuple(value, cass_data_type)
    error = cass_statement_bind_tuple_by_name(statement, name, cass_tuple)
    cass_tuple_free(cass_tuple)
    return error

# CASS_VALUE_TYPE_UDT
cdef inline bind_udt_value_by_name(CassUserType* user_type, bytes name, object value, const CassDataType* cass_data_type, CassValueType cass_value_type):
    cdef CassError error = CASS_OK

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise_if_error(CASS_ERROR_LIB_INVALID_VALUE_TYPE, f'Unknown type for UDT column {name} value "{value}"'.encode())
    elif value is None:
        error = cass_user_type_set_null_by_name(user_type, name)
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_user_type_set_bool_by_name(user_type, name, as_bool(value))
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_user_type_set_int8_by_name(user_type, name, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_user_type_set_int16_by_name(user_type, name, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_user_type_set_int32_by_name(user_type, name, int(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_user_type_set_int64_by_name(user_type, name, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_user_type_set_float_by_name(user_type, name, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_user_type_set_double_by_name(user_type, name, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = as_cass_decimal(value)
        error = cass_user_type_set_decimal_by_name(user_type, name, value, len(value), scale)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_user_type_set_string_by_name(user_type, name, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_user_type_set_string_by_name(user_type, name, as_bytes(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_user_type_set_bytes_by_name(user_type, name, as_blob(value), len(value))
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_user_type_set_uuid_by_name(user_type, name, as_cass_uuid(value))
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_user_type_set_inet_by_name(user_type, name, as_cass_inet(value))
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_user_type_set_uint32_by_name(user_type, name, as_cass_date(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_user_type_set_int64_by_name(user_type, name, as_cass_time(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_user_type_set_int64_by_name(user_type, name, as_cass_timestamp(value))
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = as_cass_duration(value)
        error = cass_user_type_set_duration_by_name(user_type, name, month, days, nanos)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        collection = get_collection(value, cass_data_type)
        error = cass_user_type_set_collection_by_name(user_type, name, collection)
        cass_collection_free(collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type)
        error = cass_user_type_set_tuple_by_name(user_type, name, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        nested_user_type = get_udt(value, cass_data_type)
        error = cass_user_type_set_user_type_by_name(user_type, name, nested_user_type)
        cass_user_type_free(nested_user_type)

    if error:
        raise_if_error(error)


cdef inline bind_udt_value_by_index(CassUserType* user_type, size_t index, object value, const CassDataType* cass_data_type, CassValueType cass_value_type):
    cdef CassCollection* collection
    cdef CassError error = CASS_OK

    if cass_value_type == CASS_VALUE_TYPE_UNKNOWN:
        raise_if_error(CASS_ERROR_LIB_INVALID_VALUE_TYPE, f'Unknown type for UDT column {index} value "{value}"'.encode())
    elif value is None:
        error = cass_user_type_set_null(user_type, index)
    elif cass_value_type == CASS_VALUE_TYPE_BOOLEAN:
        error = cass_user_type_set_bool(user_type, index, as_bool(value))
    elif cass_value_type == CASS_VALUE_TYPE_TINY_INT:
        error = cass_user_type_set_int8(user_type, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_SMALL_INT:
        error = cass_user_type_set_int16(user_type, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_INT:
        error = cass_user_type_set_int32(user_type, index, int(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BIGINT,
                             CASS_VALUE_TYPE_COUNTER):
        error = cass_user_type_set_int64(user_type, index, value)
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_user_type_set_float(user_type, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_user_type_set_double(user_type, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value, scale = as_cass_decimal(value)
        error = cass_user_type_set_decimal(user_type, index, value, len(value), scale)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_user_type_set_string(user_type, index, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        error = cass_user_type_set_string(user_type, index, as_bytes(value))
    elif cass_value_type in (CASS_VALUE_TYPE_BLOB,
                             CASS_VALUE_TYPE_VARINT,
                             CASS_VALUE_TYPE_CUSTOM):
        error = cass_user_type_set_bytes(user_type, index, as_blob(value), len(value))
    elif cass_value_type in (CASS_VALUE_TYPE_UUID,
                             CASS_VALUE_TYPE_TIMEUUID):
        error = cass_user_type_set_uuid(user_type, index, as_cass_uuid(value))
    elif cass_value_type == CASS_VALUE_TYPE_INET:
        error = cass_user_type_set_inet(user_type, index, as_cass_inet(value))
    elif cass_value_type == CASS_VALUE_TYPE_DATE:
        error = cass_user_type_set_uint32(user_type, index, as_cass_date(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIME:
        error = cass_user_type_set_int64(user_type, index, as_cass_time(value))
    elif cass_value_type == CASS_VALUE_TYPE_TIMESTAMP:
        error = cass_user_type_set_int64(user_type, index, as_cass_timestamp(value))
    elif cass_value_type == CASS_VALUE_TYPE_DURATION:
        month, days, nanos = as_cass_duration(value)
        error = cass_user_type_set_duration(user_type, index, month, days, nanos)
    elif cass_value_type in (CASS_VALUE_TYPE_MAP,
                             CASS_VALUE_TYPE_SET,
                             CASS_VALUE_TYPE_LIST):
        collection = get_collection(value, cass_data_type)
        if collection == NULL:
            raise ValueError(f'Unable to bind collection with value {value}')
        error = cass_user_type_set_collection(user_type, index, collection)
        cass_collection_free(collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type)
        if cass_tuple == NULL:
            raise ValueError(f'Unable to bind tuple with value "{value}"')
        error = cass_user_type_set_tuple(user_type, index, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        nested_user_type = get_udt(value, cass_data_type)
        error = cass_user_type_set_user_type(user_type, index, nested_user_type)
        cass_user_type_free(nested_user_type)

    if error:
        raise_if_error(error)


cdef inline CassUserType* get_udt(object value, const CassDataType* cass_data_type) except *:
    cdef CassUserType* user_type = NULL

    user_type = cass_user_type_new_from_data_type(cass_data_type)

    if user_type == NULL:
        raise ValueError(f'Unable to bind UDT with value {value}')

    if isinstance(value, dict):
        for k, v in value.items():
            sub_data_type = cass_data_type_sub_data_type_by_name(cass_data_type, k.encode())
            if sub_data_type == NULL:
                raise_if_error(CASS_ERROR_LIB_NAME_DOES_NOT_EXIST, f'Unable to bind UDT column "{k}" with value "{v}"'.encode())
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_udt_value_by_name(user_type, k.encode(), v, sub_data_type, sub_value_type)
    else:
        for i, v in enumerate(value):
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, i)
            if sub_data_type == NULL:
                raise_if_error(CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS, f'Unable to bind UDT value "{v}" with index {i}'.encode())
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_udt_value_by_index(user_type, i, v, sub_data_type, sub_value_type)

    return user_type


cdef inline CassError bind_udt(CassStatement* statement, size_t index, object value, const CassDataType* cass_data_type)  except *:
    cdef CassError error
    cdef CassUserType* user_type = NULL

    user_type = get_udt(value, cass_data_type)
    error = cass_statement_bind_user_type(statement, index, user_type)
    cass_user_type_free(user_type)
    return error


cdef inline CassError bind_udt_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type) except *:
    cdef CassError error
    cdef CassUserType* user_type = NULL

    user_type = get_udt(value, cass_data_type)
    error = cass_statement_bind_user_type_by_name(statement, name, user_type)
    cass_user_type_free(user_type)
    return error
