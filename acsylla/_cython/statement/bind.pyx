cdef extern from "utils.cpp":
    # A template of C++, the type of the days is the type of the year: it is given a long long for the years of CQL out
    # of 1..9999
    long long days_from_civil(long long y, unsigned m, unsigned d) nogil

from cpython.bytes cimport PyBytes_AS_STRING
from cpython.bytes cimport PyBytes_FromStringAndSize
from cpython.bytes cimport PyBytes_GET_SIZE
from cpython.datetime cimport PyDateTime_Check
from cpython.datetime cimport PyTime_Check
from cpython.datetime cimport date
from cpython.datetime cimport date_day
from cpython.datetime cimport date_month
from cpython.datetime cimport date_year
from cpython.datetime cimport datetime
from cpython.datetime cimport datetime_hour
from cpython.datetime cimport datetime_microsecond
from cpython.datetime cimport datetime_minute
from cpython.datetime cimport datetime_second
from cpython.datetime cimport datetime_tzinfo
from cpython.datetime cimport get_utc
from cpython.datetime cimport time
from cpython.datetime cimport time_hour
from cpython.datetime cimport time_microsecond
from cpython.datetime cimport time_minute
from cpython.datetime cimport time_second
from cpython.datetime cimport time_tzinfo
from cpython.datetime cimport timedelta
from cpython.datetime cimport timedelta_days
from cpython.datetime cimport timedelta_microseconds
from cpython.datetime cimport timedelta_seconds
from cpython.long cimport PyLong_AsLongLongAndOverflow
from cpython.long cimport PyLong_AsUnsignedLongLongMask
from cpython.mem cimport PyMem_Free
from cpython.mem cimport PyMem_Malloc
from cpython.unicode cimport PyUnicode_AsUTF8AndSize
from libc.string cimport memcmp
from libc.time cimport time_t

from decimal import Decimal
from ipaddress import IPv4Address
from ipaddress import IPv6Address
from uuid import UUID

import warnings

import_datetime()

# A datetime in UTC needs no utcoffset() call
cdef object UTC_TZ = get_utc()
cdef object ZERO_TIMEDELTA = timedelta(0)

# The warning about a decimal written as text by a statement without a session is given once
cdef bint legacy_decimal_warned = False


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
        # acsylla 1.x read a zero duration as ""
        return 0, 0, 0

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
                nanos += value * 3600000000000LL
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
                nanos += value * 60000000000LL
                unit_len = 1
            elif c == 0x73:                                # 's'
                nanos += value * 1000000000LL
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


cdef inline object as_utf8(object value, const char** data, Py_ssize_t* size):
    """The UTF-8 bytes of a text value without a copy into a new bytes object: the UTF-8 buffer of
    a str is cached in the str (an ASCII str is its own UTF-8). Returns the object that owns the
    buffer, the caller keeps it alive while the buffer is used."""
    cdef object owner = value
    if isinstance(owner, bytes):
        data[0] = PyBytes_AS_STRING(owner)
        size[0] = PyBytes_GET_SIZE(owner)
        return owner
    if not isinstance(owner, str):
        owner = str(owner)
    data[0] = PyUnicode_AsUTF8AndSize(owner, size)
    return owner


cdef inline as_blob(object value):
    if isinstance(value, bytes):
        return value
    raise ValueError(f'Value "{value}" is not bytes.')


cdef inline cass_bool_t as_bool(object value) except *:
    if value in (True, False, 0, 1):
        return cass_true if value else cass_false
    raise ValueError(f'Value "{value}" is not boolean.')


cdef inline bytes int128_as_varint(int128 value):
    """The shortest two's complement of `value`, big-endian."""
    cdef unsigned char buffer[16]
    cdef uint128 bits = <uint128>value
    cdef int i, start = 0
    for i in range(16):
        buffer[15 - i] = <unsigned char>(bits >> (8 * i))
    # The leading bytes that only repeat the sign of the next one are dropped
    while start < 15 and ((buffer[start] == 0x00 and buffer[start + 1] < 0x80) or
                          (buffer[start] == 0xFF and buffer[start + 1] >= 0x80)):
        start += 1
    return PyBytes_FromStringAndSize(<char*>buffer + start, 16 - start)


cdef inline bytes int_as_varint(object value):
    """The shortest two's complement of an int, big-endian."""
    cdef int overflow = 0
    cdef long long small = PyLong_AsLongLongAndOverflow(value, &overflow)
    if overflow == 0:
        return int128_as_varint(small)
    return acsylla_int_as_varint(value)


cdef bytes as_cass_varint(object value):
    """The varint of an int or of the str of one. bytes are taken as the two's complement of it, as acsylla 1.x did."""
    if isinstance(value, bytes):
        return value
    if isinstance(value, int) and not isinstance(value, bool):
        return int_as_varint(value)
    if isinstance(value, str):
        try:
            return int_as_varint(int(value))
        except ValueError:
            pass
    raise ValueError(f'Value "{value}" is not an int, the str of an int or the bytes of a varint.')


cdef extern from *:
    """
    #include <string.h>

    static const uint64_t acsylla_pow10[20] = {
        1ULL, 10ULL, 100ULL, 1000ULL, 10000ULL, 100000ULL, 1000000ULL, 10000000ULL, 100000000ULL, 1000000000ULL,
        10000000000ULL, 100000000000ULL, 1000000000000ULL, 10000000000000ULL, 100000000000000ULL,
        1000000000000000ULL, 10000000000000000ULL, 100000000000000000ULL, 1000000000000000000ULL,
        10000000000000000000ULL,
    };

    /* The number of 8 ASCII digits, in one 64-bit load and three multiplications as simdjson parses them */
    static inline uint32_t acsylla_eight_digits(const char* digits) {
    #if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
        uint32_t value = 0;
        for (int i = 0; i < 8; i++) {
            value = value * 10 + (uint32_t)(digits[i] - '0');
        }
        return value;
    #else
        uint64_t value;
        memcpy(&value, digits, 8);
        value -= 0x3030303030303030ULL;
        value = value * 10 + (value >> 8);
        value = ((value & 0x000000FF000000FFULL) * 0x000F424000000064ULL
                 + ((value >> 16) & 0x000000FF000000FFULL) * 0x0000271000000001ULL) >> 32;
        return (uint32_t)value;
    #endif
    }
    """
    const uint64_t* acsylla_pow10
    uint32_t acsylla_eight_digits(const char* digits) noexcept


cdef struct DecimalText:
    # The digits after the leading zeros, up to 38 of them in `unscaled`
    uint128 unscaled
    Py_ssize_t digits
    int64_t scale
    bint negative


cdef bint parse_decimal(const char* p, Py_ssize_t n, DecimalText* parsed) noexcept:
    """Parses the ASCII [+-]digits[.digits][(e|E)[+-]digits] of a decimal in C, as str() of a Decimal or a float writes
    it. False for another text, as [-]Infinity, [-]NaN, spaces, underscores or digits of other scripts."""
    cdef Py_ssize_t i = 0, mantissa = 0, fraction = 0
    cdef bint point = False, exponent_negative = False
    cdef int64_t exponent = 0
    # Up to 19 digits in a 64-bit integer, 128-bit multiplications are for each 19 of them
    cdef uint64_t chunk = 0
    cdef int chunk_digits = 0
    cdef char c
    parsed.unscaled = 0
    parsed.digits = 0
    parsed.negative = False
    if i < n and (p[i] == b'-' or p[i] == b'+'):
        parsed.negative = p[i] == b'-'
        i += 1
    while i < n:
        c = p[i]
        if b'0' <= c <= b'9':
            mantissa += 1
            if point:
                fraction += 1
            # The leading zeros of 0.05 are not digits of the unscaled value
            if parsed.digits != 0 or c != b'0':
                parsed.digits += 1
                if parsed.digits <= 38:
                    chunk = chunk * 10 + <uint64_t>(c - 48)
                    chunk_digits += 1
                    if chunk_digits == 19:
                        parsed.unscaled = parsed.unscaled * <uint128>acsylla_pow10[19] + chunk
                        chunk = 0
                        chunk_digits = 0
        elif c == b'.' and not point:
            point = True
        else:
            break
        i += 1
    if mantissa == 0:
        return False
    if chunk_digits:
        parsed.unscaled = parsed.unscaled * <uint128>acsylla_pow10[chunk_digits] + chunk
    if i < n:
        if p[i] != b'e' and p[i] != b'E':
            return False
        i += 1
        if i < n and (p[i] == b'-' or p[i] == b'+'):
            exponent_negative = p[i] == b'-'
            i += 1
        if i == n:
            return False
        while i < n:
            if not (b'0' <= p[i] <= b'9'):
                return False
            # Far beyond the 32 bits of a scale, it does not grow more
            if exponent < 100000000000LL:
                exponent = exponent * 10 + (p[i] - 48)
            i += 1
        if exponent_negative:
            exponent = -exponent
    parsed.scale = fraction - exponent
    return True


cdef inline void multiply_add(uint32_t* limbs, Py_ssize_t* size, uint32_t multiplier, uint32_t addend) noexcept:
    """limbs = limbs * multiplier + addend, limbs of 32 bits from the lowest."""
    cdef uint64_t carry = addend, product
    cdef Py_ssize_t i
    for i in range(size[0]):
        product = <uint64_t>limbs[i] * multiplier + carry
        limbs[i] = <uint32_t>product
        carry = product >> 32
    if carry:
        limbs[size[0]] = <uint32_t>carry
        size[0] += 1


cdef bytes digits_as_varint(const char* p, Py_ssize_t n, bint negative):
    """The shortest two's complement, big-endian, of the digits of a decimal text up to its exponent, without the sign
    and the point: the unscaled value of more digits than 128 bits take. Limbs of 32 bits take 8 digits at a time,
    without the Python int and its limit of digits."""
    # A limb grows by at most one for each 8 digits, times 10 ** 8 < 2 ** 27. Up to 1200 digits the digits, the limbs
    # and the bytes are on the stack
    cdef Py_ssize_t capacity = n // 8 + 2, size = 0, count = 0, length, i, j, start = 0
    cdef char stack_digits[1200]
    cdef uint32_t stack_limbs[152]
    cdef unsigned char stack_buffer[609]
    cdef char* digits = stack_digits
    cdef uint32_t* limbs = stack_limbs
    cdef unsigned char* buffer = stack_buffer
    cdef void* heap = NULL
    cdef uint32_t chunk = 0
    cdef uint32_t limb
    cdef unsigned int carry = 1
    if n > 1200:
        heap = PyMem_Malloc(capacity * sizeof(uint32_t) * 2 + 1 + n)
        if heap == NULL:
            raise MemoryError()
        limbs = <uint32_t*>heap
        buffer = <unsigned char*>(limbs + capacity)
        digits = <char*>(buffer + capacity * 4 + 1)
    try:
        # The digits without the sign and the point, parse_decimal() took the text
        for i in range(n):
            if p[i] == b'e' or p[i] == b'E':
                break
            if b'0' <= p[i] <= b'9':
                digits[count] = p[i]
                count += 1
        # The first count % 8 digits, then 8 at a time
        i = count % 8
        if i:
            for j in range(i):
                chunk = chunk * 10 + <uint32_t>(digits[j] - 48)
            multiply_add(limbs, &size, <uint32_t>acsylla_pow10[i], chunk)
        while i < count:
            multiply_add(limbs, &size, 100000000, acsylla_eight_digits(digits + i))
            i += 8
        # Big-endian, with a byte for the sign
        length = size * 4 + 1
        buffer[0] = 0
        for i in range(size):
            limb = limbs[size - 1 - i]
            buffer[1 + 4 * i] = <unsigned char>(limb >> 24)
            buffer[2 + 4 * i] = <unsigned char>(limb >> 16)
            buffer[3 + 4 * i] = <unsigned char>(limb >> 8)
            buffer[4 + 4 * i] = <unsigned char>limb
        if negative:
            # The two's complement: the bits inverted, plus one
            for i in range(length - 1, -1, -1):
                carry += <unsigned char>~buffer[i]
                buffer[i] = <unsigned char>carry
                carry >>= 8
        # The leading bytes that only repeat the sign of the next one are dropped
        while start < length - 1 and ((buffer[start] == 0x00 and buffer[start + 1] < 0x80) or
                                      (buffer[start] == 0xFF and buffer[start + 1] >= 0x80)):
            start += 1
        return PyBytes_FromStringAndSize(<char*>buffer + start, length - start)
    finally:
        PyMem_Free(heap)


cdef bint is_plain_decimal(const char* p, Py_ssize_t n) noexcept:
    """[-](0|[1-9]digits)[.digits]: str() of the Decimal of such a text is the text, or a text with an exponent whose
    digits written out are the text."""
    cdef Py_ssize_t i = 0, start
    if i < n and p[i] == b'-':
        i += 1
    start = i
    while i < n and b'0' <= p[i] <= b'9':
        i += 1
    if i == start or (p[start] == b'0' and i - start > 1):
        return False
    if i < n:
        if p[i] != b'.':
            return False
        i += 1
        start = i
        while i < n and b'0' <= p[i] <= b'9':
            i += 1
        if i == start or i < n:
            return False
    return True


cdef bytes as_legacy_decimal(object value, cass_int32_t* scale, BindOptions* options):
    """The text acsylla 1.x wrote in place of the unscaled varint of a decimal, its digits after the point as the scale.
    Other drivers and cqlsh read it as another number, a session with legacy_types=True writes it for acsylla 1.x to
    read it."""
    cdef str text
    cdef const char* p
    cdef Py_ssize_t point, n = 0
    global legacy_decimal_warned
    if options.without_session and not legacy_decimal_warned:
        legacy_decimal_warned = True
        warnings.warn(LEGACY_DECIMAL_WITHOUT_SESSION_WARNING, FutureWarning, stacklevel=1)
    if isinstance(value, (str, float)):
        text = value if isinstance(value, str) else str(value)
        p = PyUnicode_AsUTF8AndSize(text, &n)
        if is_plain_decimal(p, n):
            # As acsylla 1.x wrote a str and the str() of a float, without making the Decimal of it
            point = text.find('.')
            scale[0] = 0 if point < 0 else n - point - 1
            return PyBytes_FromStringAndSize(p, n)
    if isinstance(value, int):
        text = str(value)
    else:
        if not isinstance(value, Decimal):
            try:
                value = Decimal(value if isinstance(value, str) else str(value))
            except ArithmeticError:
                raise ValueError(f'Bad value for decimal type: "{value}"') from None
        if not value.is_finite():
            raise ValueError(f'Bad value for decimal type: "{value}"')
        text = str(value)
        if 'E' in text:
            # acsylla 1.x wrote no exponent, the digits are written out
            if value.adjusted() > 1000 or value.as_tuple().exponent < -1000:
                raise ValueError(f'Bad value for decimal type: "{value}", too many digits for the format of acsylla 1.x')
            text = format(value, 'f')
    point = text.find('.')
    scale[0] = 0 if point < 0 else len(text) - point - 1
    return text.encode('ascii')


cdef bytes as_cass_decimal(object value, cass_int32_t* scale, BindOptions* options):
    """The unscaled varint of a decimal given as a Decimal, an int, a str or a float. Its scale goes to `scale`."""
    cdef object text
    cdef const char* p
    cdef Py_ssize_t n = 0
    cdef DecimalText parsed

    # A session executes the statement only with its own legacy_types
    options.decimal_bound = True
    if isinstance(value, bool):
        raise ValueError(f'Bad value for decimal type: "{value}"')
    if options.legacy_types:
        return as_legacy_decimal(value, scale, options)
    if isinstance(value, int):
        scale[0] = 0
        return int_as_varint(value)

    # str() of a Decimal is [-]digits[.digits][E(+|-)digits] or [-]Infinity, [-]NaN, [-]sNaN, str() of a float its
    # shortest text, 3.14 and not 3.140000000000000124344978758017532527446746826171875. A str is parsed as it is
    # without making its Decimal, Decimal() parses what parse_decimal() does not take
    text = value if isinstance(value, str) else str(value)
    p = PyUnicode_AsUTF8AndSize(text, &n)
    if not parse_decimal(p, n, &parsed):
        if isinstance(value, Decimal):
            raise ValueError(f'Bad value for decimal type: "{value}"')
        try:
            text = str(Decimal(text))
        except ArithmeticError:
            raise ValueError(f'Bad value for decimal type: "{value}"') from None
        p = PyUnicode_AsUTF8AndSize(text, &n)
        if not parse_decimal(p, n, &parsed):
            raise ValueError(f'Bad value for decimal type: "{value}"')

    if parsed.scale < -2147483648LL or parsed.scale > 2147483647:
        raise ValueError(f'Bad value for decimal type: "{value}", its scale does not fit in 32 bits')
    scale[0] = <cass_int32_t>parsed.scale
    if parsed.digits <= 38:
        return int128_as_varint(-<int128>parsed.unscaled if parsed.negative else <int128>parsed.unscaled)
    return digits_as_varint(p, n, parsed.negative)


cdef inline CassUuid as_cass_uuid(object value) except *:
    cdef CassUuid cass_uuid
    cdef CassError error
    cdef object int_val
    cdef bytes b
    cdef cass_uint64_t uuid_hi, uuid_lo
    cdef cass_uint64_t time_low, time_mid, time_hi_and_version

    if isinstance(value, UUID):
        int_val = value.int
        # The low 64 bits of a Python int without creating new int objects for the masks
        uuid_hi = <cass_uint64_t>PyLong_AsUnsignedLongLongMask(int_val >> 64)
        uuid_lo = <cass_uint64_t>PyLong_AsUnsignedLongLongMask(int_val)

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
    cdef cass_uint32_t ipv4

    if not isinstance(value, (str, bytes)):
        # str() of an ipaddress object is several times slower than the whole bind of it, its int is read from its
        # slot _ip
        if isinstance(value, IPv4Address):
            ipv4 = <cass_uint32_t>PyLong_AsUnsignedLongLongMask(
                acsylla_slot(value, IPV4_IP_OFFSET) if IPV4_IP_OFFSET >= 0 else int(value))
            cass_inet.address[0] = (ipv4 >> 24) & 0xFF
            cass_inet.address[1] = (ipv4 >> 16) & 0xFF
            cass_inet.address[2] = (ipv4 >> 8) & 0xFF
            cass_inet.address[3] = ipv4 & 0xFF
            cass_inet.address_length = 4
            return cass_inet
        if isinstance(value, IPv6Address):
            acsylla_int_as_16_bytes(acsylla_slot(value, IPV6_IP_OFFSET) if IPV6_IP_OFFSET >= 0 else int(value),
                                    cass_inet.address)
            cass_inet.address_length = 16
            return cass_inet
    error = cass_inet_from_string(as_bytes(value), &cass_inet)
    if error:
        raise ValueError(f'Bad IP address value: "{value}"')
    return cass_inet


cdef inline time_t _timegm(int year, unsigned month, unsigned day, unsigned hour, unsigned minute, unsigned second) except * nogil:
    cdef int days_since_epoch = days_from_civil(year, month, day)
    return 60 * (60 * (24L * days_since_epoch + hour) + minute) + second


# The days since 1970-01-01 of CQL: 2^31 + them in 32 bits for a date, their milliseconds in 64 bits for a timestamp
cdef long long DATE_DAYS_MIN = -2147483648LL
cdef long long DATE_DAYS_MAX = 2147483647
cdef long long TIMESTAMP_DAYS_MAX = 106751991166


cdef inline Py_ssize_t _parse_iso_date(const unsigned char* b, Py_ssize_t n, long long* days):
    """Parses [-+]YYYY-MM-DD at the start of a text to the days since 1970-01-01, the years out of 1..9999 of CQL with
    more digits and a sign, as toJson() and native_types write them. Returns the length of the date, 0 when the text
    does not start with one."""
    cdef Py_ssize_t i = 0, start
    cdef long long year = 0
    cdef unsigned month, day
    cdef bint negative = False
    if n > 0 and (b[0] == 0x2d or b[0] == 0x2b):
        negative = b[0] == 0x2d
        i = 1
    start = i
    while i < n and 0x30 <= b[i] <= 0x39 and i - start < 12:
        year = year * 10 + (b[i] - 0x30)
        i += 1
    if i - start < 4 or i + 6 > n or b[i] != 0x2d or b[i + 3] != 0x2d:
        return 0
    if not (0x30 <= b[i + 1] <= 0x39 and 0x30 <= b[i + 2] <= 0x39
            and 0x30 <= b[i + 4] <= 0x39 and 0x30 <= b[i + 5] <= 0x39):
        return 0
    month = (b[i + 1] - 0x30) * 10 + (b[i + 2] - 0x30)
    day = (b[i + 4] - 0x30) * 10 + (b[i + 5] - 0x30)
    if month < 1 or month > 12 or day < 1 or day > 31:
        return 0
    days[0] = days_from_civil(-year if negative else year, month, day)
    return i + 6


cdef inline int _try_parse_iso_date_days(str s, long long* out) except -1:
    """Parse '[-+]YYYY-MM-DD' (optionally followed by T/space and time) to days
    since epoch. Returns 1 on success, 0 on format mismatch.
    """
    cdef bytes b
    try:
        b = s.encode('ascii')
    except UnicodeEncodeError:
        return 0
    cdef const unsigned char* p = b
    cdef Py_ssize_t n = len(b)
    cdef Py_ssize_t end = _parse_iso_date(p, n, out)

    if end == 0:
        return 0
    if end < n and p[end] != 0x54 and p[end] != 0x74 and p[end] != 0x20:
        return 0
    return 1


cdef inline cass_uint32_t as_cass_date(object value) except *:
    cdef cass_uint32_t cass_date
    cdef time_t epoch_secs
    cdef long long days

    if isinstance(value, str):
        if _try_parse_iso_date_days(value, &days) == 1:
            if days < DATE_DAYS_MIN or days > DATE_DAYS_MAX:
                raise ValueError(f'The date "{value}" is out of the dates of CQL')
            return <cass_uint32_t>(days + 2147483648LL)
        value = datetime.fromisoformat(value)

    if isinstance(value, date):  # datetime is a date too
        return <cass_uint32_t>(
            days_from_civil(<long long>date_year(value), date_month(value), date_day(value)) + 2147483648LL)

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


cdef inline cass_int64_t _time_to_ns(object value) except? -1:
    # The fields from the C structs of time and datetime, not attribute lookups
    cdef cass_int64_t t
    cdef object tzinfo
    cdef object offset
    if PyTime_Check(value):
        t = (<cass_int64_t>time_hour(value) * 3600 + <cass_int64_t>time_minute(value) * 60
             + time_second(value)) * 1_000_000_000 + <cass_int64_t>time_microsecond(value) * 1_000
        tzinfo = time_tzinfo(value)
    else:
        t = (<cass_int64_t>datetime_hour(value) * 3600 + <cass_int64_t>datetime_minute(value) * 60
             + datetime_second(value)) * 1_000_000_000 + <cass_int64_t>datetime_microsecond(value) * 1_000
        tzinfo = datetime_tzinfo(value)
    if tzinfo is not None:
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
    cdef int hour = 0, minute = 0, second = 0, microsecond = 0
    cdef int frac_digits
    cdef int tz_sign = 0
    cdef int tz_hour = 0, tz_min = 0
    cdef long long days
    cdef cass_int64_t ms

    cdef const unsigned char* p = b

    i = _parse_iso_date(p, n, &days)
    if i == 0:
        return 0

    if i < n:
        # Date/time separator: 'T', 't' or ' '
        if p[i] != 0x54 and p[i] != 0x74 and p[i] != 0x20:
            return 0
        i += 1
        if i + 1 >= n or not (0x30 <= p[i] <= 0x39 and 0x30 <= p[i + 1] <= 0x39):
            return 0
        hour = (p[i] - 0x30) * 10 + (p[i + 1] - 0x30)
        i += 2

        if i < n and p[i] == 0x3a:  # ':'
            i += 1
            if i + 1 >= n or not (0x30 <= p[i] <= 0x39 and 0x30 <= p[i + 1] <= 0x39):
                return 0
            minute = (p[i] - 0x30) * 10 + (p[i + 1] - 0x30)
            i += 2

            if i < n and p[i] == 0x3a:
                i += 1
                if i + 1 >= n or not (0x30 <= p[i] <= 0x39 and 0x30 <= p[i + 1] <= 0x39):
                    return 0
                second = (p[i] - 0x30) * 10 + (p[i + 1] - 0x30)
                i += 2

                if i < n and p[i] == 0x2e:  # '.'
                    i += 1
                    frac_digits = 0
                    microsecond = 0
                    while i < n and 0x30 <= p[i] <= 0x39:
                        if frac_digits < 6:
                            microsecond = microsecond * 10 + (p[i] - 0x30)
                            frac_digits += 1
                        i += 1
                    if frac_digits == 0:
                        return 0
                    while frac_digits < 6:
                        microsecond *= 10
                        frac_digits += 1

        # Optional timezone
        if i < n:
            if p[i] == 0x5a or p[i] == 0x7a:  # 'Z' / 'z'
                i += 1
            elif p[i] == 0x2b or p[i] == 0x2d:  # '+' / '-'
                tz_sign = 1 if p[i] == 0x2b else -1
                i += 1
                if i + 1 >= n or not (0x30 <= p[i] <= 0x39 and 0x30 <= p[i + 1] <= 0x39):
                    return 0
                tz_hour = (p[i] - 0x30) * 10 + (p[i + 1] - 0x30)
                i += 2
                if i < n and p[i] == 0x3a:
                    i += 1
                if i + 1 <= n and i + 1 < n and 0x30 <= p[i] <= 0x39 and 0x30 <= p[i + 1] <= 0x39:
                    tz_min = (p[i] - 0x30) * 10 + (p[i + 1] - 0x30)
                    i += 2
            else:
                return 0

        if i != n:
            return 0

    if days < -TIMESTAMP_DAYS_MAX or days > TIMESTAMP_DAYS_MAX:
        raise ValueError(f'The timestamp "{s}" is out of the timestamps of CQL')
    ms = (<cass_int64_t>days * 86400000
          + <cass_int64_t>hour * 3600000
          + <cass_int64_t>minute * 60000
          + <cass_int64_t>second * 1000
          + <cass_int64_t>(microsecond // 1000))

    if tz_sign != 0:
        ms -= <cass_int64_t>tz_sign * (tz_hour * 3600000 + tz_min * 60000)

    out[0] = ms
    return 1


cdef inline cass_int64_t _datetime_to_ms(datetime dt) except? -1:
    """The milliseconds since 1970-01-01 in UTC of a datetime, a naive one is in UTC. Its fields are read from its C
    struct and its offset in integers, not by attributes and total_seconds()."""
    cdef long long days = days_from_civil(<long long>date_year(dt), date_month(dt), date_day(dt))
    cdef cass_int64_t ms = (days * 86400000
                            + <cass_int64_t>datetime_hour(dt) * 3600000
                            + <cass_int64_t>datetime_minute(dt) * 60000
                            + <cass_int64_t>datetime_second(dt) * 1000
                            + datetime_microsecond(dt) // 1000)
    cdef object tzinfo = datetime_tzinfo(dt)
    cdef object offset
    if tzinfo is not None and tzinfo is not UTC_TZ:
        offset = dt.utcoffset()
        if offset is not None:
            ms -= ((<cass_int64_t>timedelta_days(offset) * 86400 + timedelta_seconds(offset)) * 1000000
                   + timedelta_microseconds(offset)) // 1000
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
    """The months, days and nanoseconds of a Duration, its CQL literal, a timedelta, a dateutil.relativedelta or the
    tuple (months, days, nanoseconds)."""
    cdef cass_int32_t months = 0
    cdef cass_int32_t days = 0
    cdef cass_int64_t nanos = 0
    cdef Duration duration

    if isinstance(value, Duration):
        duration = <Duration>value
        return duration.months, duration.days, duration.nanoseconds
    if isinstance(value, tuple) and len(value) == 3:
        months, days, nanos = value
    elif isinstance(value, str):
        months, days, nanos = _parse_duration_str(value)
    elif isinstance(value, timedelta):
        if value < ZERO_TIMEDELTA:
            # The days of a negative timedelta are negative and its seconds positive, a duration has one sign
            value = -value
            days = -(<timedelta>value).days
            nanos = -((<cass_int64_t>(<timedelta>value).seconds * 1000000 + (<timedelta>value).microseconds) * 1000)
        else:
            days = value.days
            nanos = (<cass_int64_t>value.seconds * 1000000 + value.microseconds) * 1000
    elif type(value).__module__ == "dateutil.relativedelta":
        duration = Duration.from_relativedelta(value)
        return duration.months, duration.days, duration.nanoseconds
    else:
        raise ValueError(f'Unknown duration format for value: "{value}"')

    return months, days, nanos


# CASS_VALUE_TYPE_MAP, CASS_VALUE_TYPE_SET, CASS_VALUE_TYPE_LIST
cdef inline void bind_collection_by_value_type(CassCollection* collection, object value, const CassDataType* cass_data_type, CassValueType cass_value_type, BindOptions* options) except *:
    cdef CassError error = CASS_OK
    cdef const char* text
    cdef Py_ssize_t text_size
    cdef object text_owner
    cdef bytes value_bytes
    cdef cass_int32_t decimal_scale

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
        text_owner = as_utf8(value, &text, &text_size)
        error = cass_collection_append_string_n(collection, text, text_size)
    elif cass_value_type == CASS_VALUE_TYPE_BLOB:
        error = cass_collection_append_bytes(collection, as_blob(value), len(value))
    elif cass_value_type == CASS_VALUE_TYPE_CUSTOM:
        value_bytes = as_cass_custom(value, cass_data_type)
        error = cass_collection_append_bytes(collection, value_bytes, len(value_bytes))
    elif cass_value_type == CASS_VALUE_TYPE_VARINT:
        value_bytes = as_cass_varint(value)
        error = cass_collection_append_bytes(collection, value_bytes, len(value_bytes))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value_bytes = as_cass_decimal(value, &decimal_scale, options)
        error = cass_collection_append_decimal(collection, value_bytes, len(value_bytes), decimal_scale)
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
        nested_collection = get_collection(value, cass_data_type, options)
        error = cass_collection_append_collection(collection, nested_collection)
        cass_collection_free(nested_collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type, options)
        error = cass_collection_append_tuple(collection, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        user_type = get_udt(value, cass_data_type, options)
        error = cass_collection_append_user_type(collection, user_type)
        cass_user_type_free(user_type)

    if error:
        raise_if_error(error)


cdef inline CassCollection* get_collection(object value, const CassDataType* cass_data_type, BindOptions* options) except *:
    cdef CassCollection* collection = NULL
    cdef CassError error
    cdef const CassDataType* sub_data_type
    cdef CassValueType sub_value_type

    collection = cass_collection_new_from_data_type(cass_data_type, len(value))

    if collection == NULL:
        raise ValueError(f'Unable to bind collection with value {value}')

    collection_type = cass_data_type_type(cass_data_type)

    try:
        if collection_type == CASS_VALUE_TYPE_MAP:
            if isinstance(value, dict):
                value = value.items()
            for k, v in value:
                sub_data_type = cass_data_type_sub_data_type(cass_data_type, 0)
                sub_value_type = cass_data_type_type(sub_data_type)
                bind_collection_by_value_type(collection, k, sub_data_type, sub_value_type, options)
                sub_data_type = cass_data_type_sub_data_type(cass_data_type, 1)
                sub_value_type = cass_data_type_type(sub_data_type)
                bind_collection_by_value_type(collection, v, sub_data_type, sub_value_type, options)
        else:
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, 0)
            sub_value_type = cass_data_type_type(sub_data_type)
            # The element type is the same for all elements, the common ones skip the dispatch
            if sub_value_type == CASS_VALUE_TYPE_INT:
                for v in value:
                    error = cass_collection_append_int32(collection, v if type(v) is int else int(v))
                    if error:
                        raise_if_error(error)
            elif sub_value_type == CASS_VALUE_TYPE_BIGINT:
                for v in value:
                    error = cass_collection_append_int64(collection, v if type(v) is int else int(v))
                    if error:
                        raise_if_error(error)
            else:
                for v in value:
                    bind_collection_by_value_type(collection, v, sub_data_type, sub_value_type, options)
    except BaseException:
        # A value that can not be bound, the collection is not returned to be freed
        cass_collection_free(collection)
        raise

    return collection


cdef inline CassError bind_collection(CassStatement* statement, int index, object value, const CassDataType* cass_data_type, BindOptions* options) except *:
    cdef CassCollection* collection
    cdef CassError error
    collection = get_collection(value, cass_data_type, options)
    error = cass_statement_bind_collection(statement, index, collection)
    cass_collection_free(collection)
    return error

cdef inline  CassError bind_collection_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type, BindOptions* options) except *:
    cdef CassCollection* collection
    cdef CassError error
    collection = get_collection(value, cass_data_type, options)
    error = cass_statement_bind_collection_by_name(statement, name, collection)
    cass_collection_free(collection)
    return error

# CASS_VALUE_TYPE_TUPLE
cdef inline void bind_tuple_by_value_type(CassTuple* cass_tuple, size_t index, object value, const CassDataType* cass_data_type, CassValueType cass_value_type, BindOptions* options) except *:
    cdef CassError error = CASS_OK
    cdef const char* text
    cdef Py_ssize_t text_size
    cdef object text_owner
    cdef bytes value_bytes
    cdef cass_int32_t decimal_scale

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
        text_owner = as_utf8(value, &text, &text_size)
        error = cass_tuple_set_string_n(cass_tuple, index, text, text_size)
    elif cass_value_type == CASS_VALUE_TYPE_BLOB:
        error = cass_tuple_set_bytes(cass_tuple, index, as_blob(value), len(value))
    elif cass_value_type == CASS_VALUE_TYPE_CUSTOM:
        value_bytes = as_cass_custom(value, cass_data_type)
        error = cass_tuple_set_bytes(cass_tuple, index, value_bytes, len(value_bytes))
    elif cass_value_type == CASS_VALUE_TYPE_VARINT:
        value_bytes = as_cass_varint(value)
        error = cass_tuple_set_bytes(cass_tuple, index, value_bytes, len(value_bytes))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value_bytes = as_cass_decimal(value, &decimal_scale, options)
        error = cass_tuple_set_decimal(cass_tuple, index, value_bytes, len(value_bytes), decimal_scale)
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
        collection = get_collection(value, cass_data_type, options)
        error = cass_tuple_set_collection(cass_tuple, index, collection)
        cass_collection_free(collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        nested_tuple = get_tuple(value, cass_data_type, options)
        error = cass_tuple_set_tuple(cass_tuple, index, nested_tuple)
        cass_tuple_free(nested_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        user_type = get_udt(value, cass_data_type, options)
        error = cass_tuple_set_user_type(cass_tuple, index, user_type)
        cass_user_type_free(user_type)

    if error:
        raise_if_error(error)


cdef inline CassTuple* get_tuple(object value, const CassDataType* cass_data_type, BindOptions* options) except *:
    cdef CassTuple * cass_tuple = NULL
    cdef CassError error
    cdef size_t type_count
    cdef size_t tuple_len = len(value)

    type_count = cass_data_type_sub_type_count(cass_data_type)
    if tuple_len > type_count:
        raise ValueError(
            f'Wrong tuple size (must be {type_count}) for value {value}')

    cass_tuple = cass_tuple_new(tuple_len)

    cdef size_t i = 0
    try:
        for v in value:
            sub_data_type = cass_data_type_sub_data_type(cass_data_type, i)
            if sub_data_type == NULL:
                raise_if_error(CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS, f'Unable to bind Tuple index {i}'.encode())
            sub_value_type = cass_data_type_type(sub_data_type)
            bind_tuple_by_value_type(cass_tuple, i, v, sub_data_type, sub_value_type, options)
            i += 1
    except BaseException:
        # A value that can not be bound, the tuple is not returned to be freed
        cass_tuple_free(cass_tuple)
        raise

    return cass_tuple


cdef inline bind_tuple(CassStatement* statement, size_t index, object value, const CassDataType* cass_data_type, BindOptions* options):
    cdef CassError error
    cass_tuple = get_tuple(value, cass_data_type, options)
    error = cass_statement_bind_tuple(statement, index, cass_tuple)
    cass_tuple_free(cass_tuple)
    return error

cdef inline bind_tuple_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type, BindOptions* options):
    cdef CassError error
    cass_tuple = get_tuple(value, cass_data_type, options)
    error = cass_statement_bind_tuple_by_name(statement, name, cass_tuple)
    cass_tuple_free(cass_tuple)
    return error

# CASS_VALUE_TYPE_UDT
cdef inline bind_udt_value_by_name(CassUserType* user_type, bytes name, object value, const CassDataType* cass_data_type, CassValueType cass_value_type, BindOptions* options):
    cdef CassError error = CASS_OK
    cdef const char* text
    cdef Py_ssize_t text_size
    cdef object text_owner
    cdef bytes value_bytes
    cdef cass_int32_t decimal_scale

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
        value_bytes = as_cass_decimal(value, &decimal_scale, options)
        error = cass_user_type_set_decimal_by_name(user_type, name, value_bytes, len(value_bytes), decimal_scale)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_user_type_set_string_by_name(user_type, name, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        text_owner = as_utf8(value, &text, &text_size)
        error = cass_user_type_set_string_by_name_n(user_type, name, len(name), text, text_size)
    elif cass_value_type == CASS_VALUE_TYPE_BLOB:
        error = cass_user_type_set_bytes_by_name(user_type, name, as_blob(value), len(value))
    elif cass_value_type == CASS_VALUE_TYPE_CUSTOM:
        value_bytes = as_cass_custom(value, cass_data_type)
        error = cass_user_type_set_bytes_by_name(user_type, name, value_bytes, len(value_bytes))
    elif cass_value_type == CASS_VALUE_TYPE_VARINT:
        value_bytes = as_cass_varint(value)
        error = cass_user_type_set_bytes_by_name(user_type, name, value_bytes, len(value_bytes))
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
        collection = get_collection(value, cass_data_type, options)
        error = cass_user_type_set_collection_by_name(user_type, name, collection)
        cass_collection_free(collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type, options)
        error = cass_user_type_set_tuple_by_name(user_type, name, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        nested_user_type = get_udt(value, cass_data_type, options)
        error = cass_user_type_set_user_type_by_name(user_type, name, nested_user_type)
        cass_user_type_free(nested_user_type)

    if error:
        raise_if_error(error)


cdef inline bind_udt_value_by_index(CassUserType* user_type, size_t index, object value, const CassDataType* cass_data_type, CassValueType cass_value_type, BindOptions* options):
    cdef CassCollection* collection
    cdef CassError error = CASS_OK
    cdef const char* text
    cdef Py_ssize_t text_size
    cdef object text_owner
    cdef bytes value_bytes
    cdef cass_int32_t decimal_scale

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
        error = cass_user_type_set_int64(user_type, index, int(value))
    elif cass_value_type == CASS_VALUE_TYPE_FLOAT:
        error = cass_user_type_set_float(user_type, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DOUBLE:
        error = cass_user_type_set_double(user_type, index, float(value))
    elif cass_value_type == CASS_VALUE_TYPE_DECIMAL:
        value_bytes = as_cass_decimal(value, &decimal_scale, options)
        error = cass_user_type_set_decimal(user_type, index, value_bytes, len(value_bytes), decimal_scale)
    elif cass_value_type == CASS_VALUE_TYPE_ASCII:
        error = cass_user_type_set_string(user_type, index, as_bytes(value, 'ascii'))
    elif cass_value_type in (CASS_VALUE_TYPE_TEXT,
                             CASS_VALUE_TYPE_VARCHAR):
        text_owner = as_utf8(value, &text, &text_size)
        error = cass_user_type_set_string_n(user_type, index, text, text_size)
    elif cass_value_type == CASS_VALUE_TYPE_BLOB:
        error = cass_user_type_set_bytes(user_type, index, as_blob(value), len(value))
    elif cass_value_type == CASS_VALUE_TYPE_CUSTOM:
        value_bytes = as_cass_custom(value, cass_data_type)
        error = cass_user_type_set_bytes(user_type, index, value_bytes, len(value_bytes))
    elif cass_value_type == CASS_VALUE_TYPE_VARINT:
        value_bytes = as_cass_varint(value)
        error = cass_user_type_set_bytes(user_type, index, value_bytes, len(value_bytes))
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
        collection = get_collection(value, cass_data_type, options)
        if collection == NULL:
            raise ValueError(f'Unable to bind collection with value {value}')
        error = cass_user_type_set_collection(user_type, index, collection)
        cass_collection_free(collection)
    elif cass_value_type == CASS_VALUE_TYPE_TUPLE:
        cass_tuple = get_tuple(value, cass_data_type, options)
        if cass_tuple == NULL:
            raise ValueError(f'Unable to bind tuple with value "{value}"')
        error = cass_user_type_set_tuple(user_type, index, cass_tuple)
        cass_tuple_free(cass_tuple)
    elif cass_value_type == CASS_VALUE_TYPE_UDT:
        nested_user_type = get_udt(value, cass_data_type, options)
        error = cass_user_type_set_user_type(user_type, index, nested_user_type)
        cass_user_type_free(nested_user_type)

    if error:
        raise_if_error(error)


cdef inline CassUserType* get_udt(object value, const CassDataType* cass_data_type, BindOptions* options) except *:
    cdef CassUserType* user_type = NULL

    user_type = cass_user_type_new_from_data_type(cass_data_type)

    if user_type == NULL:
        raise ValueError(f'Unable to bind UDT with value {value}')

    cdef size_t i = 0
    cdef size_t field_count
    cdef Py_ssize_t field
    cdef bytes name
    try:
        if isinstance(value, dict):
            field_count = cass_data_type_sub_type_count(cass_data_type)
            for k, v in value.items():
                # The field named exactly like the key, set by index: no lookups by name in the driver
                field = udt_field_index(cass_data_type, field_count, k, i) if isinstance(k, str) else -1
                if field >= 0:
                    sub_data_type = cass_data_type_sub_data_type(cass_data_type, field)
                    bind_udt_value_by_index(user_type, field, v, sub_data_type, cass_data_type_type(sub_data_type), options)
                else:
                    # The driver's lookup by name, which ignores case unless the name is quoted
                    name = k.encode()
                    sub_data_type = cass_data_type_sub_data_type_by_name(cass_data_type, name)
                    if sub_data_type == NULL:
                        raise_if_error(CASS_ERROR_LIB_NAME_DOES_NOT_EXIST, f'Unable to bind UDT column "{k}" with value "{v}"'.encode())
                    bind_udt_value_by_name(user_type, name, v, sub_data_type, cass_data_type_type(sub_data_type), options)
                i += 1
        else:
            for v in value:
                sub_data_type = cass_data_type_sub_data_type(cass_data_type, i)
                if sub_data_type == NULL:
                    raise_if_error(CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS, f'Unable to bind UDT value "{v}" with index {i}'.encode())
                sub_value_type = cass_data_type_type(sub_data_type)
                bind_udt_value_by_index(user_type, i, v, sub_data_type, sub_value_type, options)
                i += 1
    except BaseException:
        # A value that can not be bound, the UDT is not returned to be freed
        cass_user_type_free(user_type)
        raise

    return user_type


cdef inline Py_ssize_t udt_field_index(const CassDataType* cass_data_type, size_t field_count, str key, size_t hint) except -2:
    """Index of the UDT field named exactly `key`, or -1. The field at `hint` is tried first, the
    keys of a dict usually come in the order of the fields."""
    cdef const char* key_data
    cdef Py_ssize_t key_size
    cdef const char* field_name
    cdef size_t field_name_size
    cdef size_t i
    key_data = PyUnicode_AsUTF8AndSize(key, &key_size)
    if hint < field_count and cass_data_type_sub_type_name(cass_data_type, hint, &field_name, &field_name_size) == CASS_OK:
        if field_name_size == <size_t>key_size and memcmp(field_name, key_data, key_size) == 0:
            return hint
    for i in range(field_count):
        if i == hint:
            continue
        if cass_data_type_sub_type_name(cass_data_type, i, &field_name, &field_name_size) != CASS_OK:
            continue
        if field_name_size == <size_t>key_size and memcmp(field_name, key_data, key_size) == 0:
            return i
    return -1


cdef inline CassError bind_udt(CassStatement* statement, size_t index, object value, const CassDataType* cass_data_type, BindOptions* options)  except *:
    cdef CassError error
    cdef CassUserType* user_type = NULL

    user_type = get_udt(value, cass_data_type, options)
    error = cass_statement_bind_user_type(statement, index, user_type)
    cass_user_type_free(user_type)
    return error


cdef inline CassError bind_udt_by_name(CassStatement* statement, bytes name, object value, const CassDataType* cass_data_type, BindOptions* options) except *:
    cdef CassError error
    cdef CassUserType* user_type = NULL

    user_type = get_udt(value, cass_data_type, options)
    error = cass_statement_bind_user_type_by_name(statement, name, user_type)
    cass_user_type_free(user_type)
    return error
