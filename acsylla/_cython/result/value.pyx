cdef extern from "utils.cpp":
    # A template of C++, the type of the days is the type of the argument: it is given a long long, an unsigned one wraps
    # the days before 1970 around and an int does not hold the days of the years before -5877641 or after 5881580
    void civil_from_days(long long z, int* year, unsigned* month, unsigned* day) nogil

cdef extern from *:
    """
    typedef __int128 acsylla_int128;
    typedef unsigned __int128 acsylla_uint128;
    static const unsigned long long ACSYLLA_1E19 = 10000000000000000000ULL;
    """
    # The 128-bit integers of GCC and Clang, a decimal of up to 38 digits is converted in them
    ctypedef long long int128 "acsylla_int128"
    ctypedef unsigned long long uint128 "acsylla_uint128"
    const unsigned long long ACSYLLA_1E19

cdef extern from *:
    """
    /* An int of a varint of any length (two's complement, big-endian), PyLong_FromNativeBytes() is public from
       Python 3.13 */
    static PyObject* acsylla_varint_as_int(const unsigned char* varint, size_t size) {
    #if PY_VERSION_HEX >= 0x030D0000
        return PyLong_FromNativeBytes(varint, size, Py_ASNATIVEBYTES_BIG_ENDIAN);
    #else
        return _PyLong_FromByteArray(varint, size, 0, 1);
    #endif
    }

    /* The shortest varint of an int, PyLong_AsNativeBytes() is public from Python 3.13 */
    static PyObject* acsylla_int_as_varint(PyObject* value) {
        unsigned char stack_buffer[64];
        unsigned char* buffer = stack_buffer;
        Py_ssize_t size, start = 0;
        PyObject* varint;
    #if PY_VERSION_HEX >= 0x030D0000
        size = PyLong_AsNativeBytes(value, NULL, 0, Py_ASNATIVEBYTES_BIG_ENDIAN);
        if (size < 0) {
            return NULL;
        }
    #else
        size_t bits = _PyLong_NumBits(value);
        if (bits == (size_t)-1 && PyErr_Occurred()) {
            return NULL;
        }
        /* With a sign bit */
        size = (Py_ssize_t)(bits / 8 + 1);
    #endif
        if (size > (Py_ssize_t)sizeof(stack_buffer)) {
            buffer = (unsigned char*)PyMem_Malloc(size);
            if (buffer == NULL) {
                return PyErr_NoMemory();
            }
        }
    #if PY_VERSION_HEX >= 0x030D0000
        if (PyLong_AsNativeBytes(value, buffer, size, Py_ASNATIVEBYTES_BIG_ENDIAN) < 0) {
    #else
        if (_PyLong_AsByteArray((PyLongObject*)value, buffer, size, 0, 1) < 0) {
    #endif
            if (buffer != stack_buffer) {
                PyMem_Free(buffer);
            }
            return NULL;
        }
        /* The size may have room for a sign bit it does not need, the leading bytes that only repeat the sign of the
           next one are dropped */
        while (start < size - 1 && ((buffer[start] == 0x00 && buffer[start + 1] < 0x80) ||
                                    (buffer[start] == 0xFF && buffer[start + 1] >= 0x80))) {
            start++;
        }
        varint = PyBytes_FromStringAndSize((const char*)buffer + start, size - start);
        if (buffer != stack_buffer) {
            PyMem_Free(buffer);
        }
        return varint;
    }
    """
    object acsylla_varint_as_int(const unsigned char* varint, size_t size)
    bytes acsylla_int_as_varint(object value)

cdef extern from *:
    """
    /* PyMemberDef is in Python.h from Python 3.12 */
    #if PY_VERSION_HEX < 0x030C0000
    #include "structmember.h"
    #endif

    /* The offset in its objects of a slot of __slots__, from the member descriptor of the slot */
    static Py_ssize_t acsylla_member_offset(PyObject* descriptor) {
        return ((PyMemberDescrObject*)descriptor)->d_member->offset;
    }

    /* An object of a class of __slots__ as object.__new__() makes it, with first in its slot at first_offset and
       second in the one at second_offset when it is not -1. The slots take new references to the values */
    static PyObject* acsylla_new_with_slots(PyObject* type, PyObject* first, Py_ssize_t first_offset,
                                            PyObject* second, Py_ssize_t second_offset) {
        PyObject* object = ((PyTypeObject*)type)->tp_alloc((PyTypeObject*)type, 0);
        if (object == NULL) {
            return NULL;
        }
        Py_INCREF(first);
        *(PyObject**)((char*)object + first_offset) = first;
        if (second_offset >= 0) {
            Py_INCREF(second);
            *(PyObject**)((char*)object + second_offset) = second;
        }
        return object;
    }

    /* A new reference to the object in the slot at offset, an AttributeError for an empty slot */
    static PyObject* acsylla_slot(PyObject* object, Py_ssize_t offset) {
        PyObject* value = *(PyObject**)((char*)object + offset);
        if (value == NULL) {
            PyErr_SetString(PyExc_AttributeError, "an empty slot");
            return NULL;
        }
        Py_INCREF(value);
        return value;
    }

    /* The 16 unsigned big-endian bytes of an int, -1 with an exception for an int that does not fit in them */
    static int acsylla_int_as_16_bytes(PyObject* value, unsigned char* output) {
    #if PY_VERSION_HEX >= 0x030D0000
        Py_ssize_t size = PyLong_AsNativeBytes(value, output, 16,
                                               Py_ASNATIVEBYTES_BIG_ENDIAN | Py_ASNATIVEBYTES_UNSIGNED_BUFFER |
                                               Py_ASNATIVEBYTES_REJECT_NEGATIVE);
        if (size < 0) {
            return -1;
        }
        if (size > 16) {
            PyErr_SetString(PyExc_OverflowError, "an int of more than 16 bytes");
            return -1;
        }
        return 0;
    #else
        return _PyLong_AsByteArray((PyLongObject*)value, output, 16, 0, 0);
    #endif
    }

    /* The int of unsigned big-endian bytes */
    static PyObject* acsylla_unsigned_int(const unsigned char* data, size_t size) {
    #if PY_VERSION_HEX >= 0x030D0000
        return PyLong_FromUnsignedNativeBytes(data, size, Py_ASNATIVEBYTES_BIG_ENDIAN);
    #else
        return _PyLong_FromByteArray(data, size, 0, 0);
    #endif
    }
    """
    Py_ssize_t acsylla_member_offset(object descriptor)
    object acsylla_new_with_slots(object type, object first, Py_ssize_t first_offset, object second,
                                  Py_ssize_t second_offset)
    object acsylla_unsigned_int(const unsigned char* data, size_t size)
    object acsylla_slot(object obj, Py_ssize_t offset)
    int acsylla_int_as_16_bytes(object value, unsigned char* output) except -1

cimport cython

from cpython.datetime cimport date_new
from cpython.datetime cimport datetime_new
from cpython.datetime cimport get_utc
from cpython.datetime cimport import_datetime
from cpython.datetime cimport time_new
from cpython.long cimport PyLong_FromLongLong
from cpython.long cimport PyLong_FromUnsignedLong
from cpython.mem cimport PyMem_Free
from cpython.mem cimport PyMem_Malloc
from cpython.unicode cimport PyUnicode_1BYTE_KIND
from cpython.unicode cimport PyUnicode_AsUTF8AndSize
from cpython.unicode cimport PyUnicode_FromKindAndData
from libc.string cimport memcpy

from decimal import Context
from decimal import Decimal
from decimal import MAX_EMAX
from decimal import MAX_PREC
from decimal import MIN_EMIN
from ipaddress import IPv4Address
from ipaddress import IPv6Address
from types import MemberDescriptorType
from uuid import SafeUUID
from uuid import UUID

import_datetime()

# Changes the exponent of a Decimal without rounding its digits
cdef object DECIMAL_EXACT = Context(prec=MAX_PREC, Emax=MAX_EMAX, Emin=MIN_EMIN)

cdef object slot_offsets(object cls, tuple names):
    """The offsets of the slots `names` in the objects of `cls`, None when these slots are not all the fields of its
    objects as object.__new__() makes them: another slot, a __dict__ or a __new__ of its own."""
    cdef list offsets = []
    expected = set(names) | {"__weakref__"}
    if cls.__new__ is not object.__new__:
        return None
    for base in cls.__mro__[:-1]:
        if "__slots__" not in base.__dict__:
            return None
        slots = base.__dict__["__slots__"]
        if not set((slots,) if isinstance(slots, str) else slots) <= expected:
            return None
    for name in names:
        descriptor = next((base.__dict__[name] for base in cls.__mro__ if name in base.__dict__), None)
        if not isinstance(descriptor, MemberDescriptorType):
            return None
        offsets.append(acsylla_member_offset(descriptor))
    return tuple(offsets)


# uuid.UUID, IPv4Address and IPv6Address are made with their slots written at their offsets, as UUID._from_int() of
# Python 3.14 makes a UUID: several times faster than their constructors. A class that is not made of these slots any
# more, or that is not equal then to the one of its constructor, is made by its constructor
cdef object UUID_UNKNOWN = SafeUUID.unknown
cdef Py_ssize_t UUID_INT_OFFSET = -1
cdef Py_ssize_t UUID_IS_SAFE_OFFSET = -1
cdef Py_ssize_t IPV4_IP_OFFSET = -1
cdef Py_ssize_t IPV6_IP_OFFSET = -1
cdef Py_ssize_t IPV6_SCOPE_ID_OFFSET = -1


cdef void find_slots() except *:
    global UUID_INT_OFFSET, UUID_IS_SAFE_OFFSET, IPV4_IP_OFFSET, IPV6_IP_OFFSET, IPV6_SCOPE_ID_OFFSET
    offsets = slot_offsets(UUID, ("int", "is_safe"))
    if offsets is not None:
        number = int.from_bytes(bytes(range(16)), "big")
        made = acsylla_new_with_slots(UUID, number, offsets[0], UUID_UNKNOWN, offsets[1])
        if made == UUID(int=number) and made.int == number and made.is_safe is UUID_UNKNOWN:
            UUID_INT_OFFSET, UUID_IS_SAFE_OFFSET = offsets
    offsets = slot_offsets(IPv4Address, ("_ip",))
    if offsets is not None:
        made = acsylla_new_with_slots(IPv4Address, 3232235876, offsets[0], None, -1)
        if made == IPv4Address(3232235876) and str(made) == "192.168.1.100":
            IPV4_IP_OFFSET = offsets[0]
    offsets = slot_offsets(IPv6Address, ("_ip", "_scope_id"))
    if offsets is not None:
        number = int.from_bytes(bytes(range(16)), "big")
        made = acsylla_new_with_slots(IPv6Address, number, offsets[0], None, offsets[1])
        if made == IPv6Address(number) and str(made) == str(IPv6Address(number)) and made.scope_id is None:
            IPV6_IP_OFFSET, IPV6_SCOPE_ID_OFFSET = offsets


find_slots()


cdef inline object get_cass_value(const CassValue* cass_value, int8_t flags):
    cdef CassValueType cass_type

    cdef cass_bool_t value_is_null = cass_value_is_null(cass_value)
    if value_is_null:
        return None

    cass_type = cass_value_type(cass_value)

    if cass_type == CASS_VALUE_TYPE_UNKNOWN:
        return None
    elif cass_type == CASS_VALUE_TYPE_TINY_INT:
        return _int8(cass_value)
    elif cass_type == CASS_VALUE_TYPE_SMALL_INT:
        return _int16(cass_value)
    elif cass_type == CASS_VALUE_TYPE_INT:
        return _int32(cass_value)
    elif cass_type in (CASS_VALUE_TYPE_BIGINT, CASS_VALUE_TYPE_COUNTER):
        return _int64(cass_value)
    elif cass_type in (CASS_VALUE_TYPE_UUID, CASS_VALUE_TYPE_TIMEUUID):
        return _uuid(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_FLOAT:
        return _float(cass_value)
    elif cass_type == CASS_VALUE_TYPE_DOUBLE:
        return _double(cass_value)
    elif cass_type == CASS_VALUE_TYPE_DECIMAL:
        return _decimal(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_BOOLEAN:
        return _bool(cass_value)
    elif cass_type in (CASS_VALUE_TYPE_ASCII,
                       CASS_VALUE_TYPE_TEXT,
                       CASS_VALUE_TYPE_VARCHAR):
        return _string(cass_value)
    elif cass_type == CASS_VALUE_TYPE_BLOB:
        return _bytes(cass_value)
    elif cass_type == CASS_VALUE_TYPE_CUSTOM:
        return _custom(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_VARINT:
        return _varint(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_INET:
        return _inet(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_DATE:
        return _date(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_TIME:
        return _time(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_TIMESTAMP:
        return _timestamp(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_DURATION:
        return _duration(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_MAP:
        return _map(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_SET:
        return _set(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_LIST:
        return _list(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_TUPLE:
        return _tuple(cass_value, flags)
    elif cass_type == CASS_VALUE_TYPE_UDT:
        return _udt(cass_value, flags)
    else:
        raise ValueError(f"Type not supported {cass_type}")

cdef inline object _int8(const CassValue* cass_value):
    """ Returns the int value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int8_t output
    cdef CassError error
    error = cass_value_get_int8(cass_value, <cass_int8_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    return output


cdef inline object _int16(const CassValue* cass_value):
    """ Returns the int value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int16_t output
    cdef CassError error
    error = cass_value_get_int16(cass_value, <cass_int16_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    return output


cdef inline object _int32(const CassValue* cass_value):
    """ Returns the int value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int32_t output
    cdef CassError error
    error = cass_value_get_int32(cass_value, <cass_int32_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    return output


cdef inline object _int64(const CassValue* cass_value):
    """ Returns the int value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int64_t output
    cdef CassError error
    error = cass_value_get_int64(cass_value, <cass_int64_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    return output


cdef inline object uuid_text(const cass_byte_t* data):
    """The xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx of a uuid."""
    cdef char buffer[36]
    cdef Py_ssize_t i, length = 0
    cdef const char* hexdigits = "0123456789abcdef"
    for i in range(16):
        if i == 4 or i == 6 or i == 8 or i == 10:
            buffer[length] = b"-"
            length += 1
        buffer[length] = hexdigits[data[i] >> 4]
        buffer[length + 1] = hexdigits[data[i] & 15]
        length += 2
    return PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, buffer, 36)


cdef inline object _uuid(const CassValue* cass_value, int8_t flags):
    """ Returns the uuid.UUID of a uuid or timeuuid column, its str with native_types or legacy_types.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef const cass_byte_t* data = NULL
    cdef size_t size = 0
    cdef CassError error

    error = cass_value_get_bytes(cass_value, &data, &size)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    if size == 0:
        # An empty value
        return None
    if size != 16:
        raise ValueError(f"a uuid of {size} bytes")
    if flags & (NATIVE_TYPES | LEGACY_TYPES):
        return uuid_text(data)
    if UUID_INT_OFFSET >= 0:
        return acsylla_new_with_slots(UUID, acsylla_unsigned_int(data, 16), UUID_INT_OFFSET, UUID_UNKNOWN,
                                      UUID_IS_SAFE_OFFSET)
    return UUID(bytes=data[:16])


cdef inline object _float(const CassValue* cass_value):
    """ Returns the float value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_float_t output
    cdef CassError error

    error = cass_value_get_float(cass_value, &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    return output


cdef inline object _double(const CassValue* cass_value):
    """ Returns the double value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef double output
    cdef CassError error

    error = cass_value_get_double(cass_value, <cass_double_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    return output


cdef inline bint varint_as_int128(const cass_byte_t* varint, size_t size, int128* output):
    """The value of a varint (two's complement, big-endian) of up to 16 bytes, False for a longer one."""
    cdef uint128 value
    cdef size_t i
    if size > 16:
        return False
    value = ~(<uint128>0) if size and varint[0] & 0x80 else 0
    for i in range(size):
        value = (value << 8) | varint[i]
    output[0] = <int128>value
    return True


@cython.cdivision(True)
cdef inline Py_ssize_t write_digits(char* buffer, uint64_t value):
    """Writes the decimal digits of `value`, snprintf costs several times more. Returns their number."""
    cdef char reversed_[20]
    cdef Py_ssize_t count = 0, i
    while True:
        reversed_[count] = <char>(48 + value % 10)
        count += 1
        value //= 10
        if value == 0:
            break
    for i in range(count):
        buffer[i] = reversed_[count - 1 - i]
    return count


@cython.cdivision(True)
cdef inline Py_ssize_t write_digits_128(char* buffer, uint128 value):
    """Writes the decimal digits of `value` up to 2^127, one 128-bit division splits it into 64-bit halves."""
    cdef uint64_t high, low
    cdef Py_ssize_t count, i
    if value >> 64 == 0:
        return write_digits(buffer, <uint64_t>value)
    high = <uint64_t>(value // ACSYLLA_1E19)
    low = <uint64_t>(value - <uint128>high * ACSYLLA_1E19)
    count = write_digits(buffer, high)
    # The low half has 19 digits with its leading zeros
    for i in range(count + 18, count - 1, -1):
        buffer[i] = <char>(48 + low % 10)
        low //= 10
    return count + 19


cdef Py_ssize_t write_decimal_text(char* buffer, const char* digits, Py_ssize_t count, bint negative,
                                   cass_int32_t scale):
    """str() of the Decimal: the to-scientific-string of the decimal arithmetic specification. Returns its length."""
    cdef Py_ssize_t length = 0, point
    cdef int64_t exponent = -(<int64_t>scale)
    cdef int64_t adjusted = exponent + count - 1
    if negative:
        buffer[0] = b"-"
        length = 1
    if exponent <= 0 and adjusted >= -6:
        # Without an exponent: 1234.5678, 0.000001
        point = count + exponent
        if point > 0:
            memcpy(buffer + length, digits, point)
            length += point
            if exponent < 0:
                buffer[length] = b"."
                memcpy(buffer + length + 1, digits + point, count - point)
                length += 1 + count - point
        else:
            buffer[length] = b"0"
            buffer[length + 1] = b"."
            length += 2
            while point < 0:
                buffer[length] = b"0"
                length += 1
                point += 1
            memcpy(buffer + length, digits, count)
            length += count
    else:
        # With an exponent: 1E+10, 1.23E-7
        buffer[length] = digits[0]
        length += 1
        if count > 1:
            buffer[length] = b"."
            memcpy(buffer + length + 1, digits + 1, count - 1)
            length += count
        buffer[length] = b"E"
        buffer[length + 1] = b"+" if adjusted >= 0 else b"-"
        length += 2
        length += write_digits(buffer + length, <uint64_t>(adjusted if adjusted >= 0 else -adjusted))
    return length


cdef object decimal_from_digits(const char* digits, Py_ssize_t count, bint negative, cass_int32_t scale,
                                int8_t flags):
    """The Decimal of [-]digits * 10 ** -scale, its str() with native_types. The str() is made in C, Decimal parses it
    back to the same digits and exponent, a text with a point the fastest."""
    cdef char stack_buffer[96]
    cdef char* buffer
    cdef Py_ssize_t length
    # Room for the digits, a sign, a point, "0." with five zeros and an exponent with its sign
    if count + 48 <= 96:
        length = write_decimal_text(stack_buffer, digits, count, negative, scale)
        text = PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, stack_buffer, length)
    else:
        buffer = <char*>PyMem_Malloc(count + 48)
        if buffer == NULL:
            raise MemoryError()
        try:
            length = write_decimal_text(buffer, digits, count, negative, scale)
            text = PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, buffer, length)
        finally:
            PyMem_Free(buffer)
    return text if flags & NATIVE_TYPES else Decimal(text)


cdef inline bint is_legacy_decimal(const cass_byte_t* varint, size_t size, cass_int32_t scale):
    """True when the varint is the text acsylla 1.x wrote in place of it: [+-]digits[.digits] with as many digits after
    the point as the scale."""
    cdef size_t i = 0, start
    if size and (varint[0] == 43 or varint[0] == 45):
        i = 1
    start = i
    while i < size and 48 <= varint[i] <= 57:
        i += 1
    if i == start:
        return False
    if i == size:
        return scale == 0
    if varint[i] != 46:
        return False
    i += 1
    start = i
    while i < size and 48 <= varint[i] <= 57:
        i += 1
    return i == size and i > start and <Py_ssize_t>(size - start) == scale


cdef inline object _decimal(const CassValue* cass_value, int8_t flags):
    """ Returns the decimal value of a column, its str() with native_types.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef size_t varint_size = 0
    cdef const cass_byte_t* varint = NULL
    cdef cass_int32_t scale
    cdef int128 unscaled
    cdef char digits[40]
    cdef const char* text_digits
    cdef Py_ssize_t count
    cdef CassError error

    error = cass_value_get_decimal(cass_value, &varint, &varint_size, &scale)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    # The varint points into the buffer of the result, it lives as long as the result
    if flags & LEGACY_TYPES and is_legacy_decimal(varint, varint_size, scale):
        # A session with legacy_types=True reads the text acsylla 1.x wrote as acsylla 1.x did, the other decimals as
        # they are
        text = PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, varint, varint_size)
        return text if flags & NATIVE_TYPES else Decimal(text)
    if varint_as_int128(varint, varint_size, &unscaled):
        count = write_digits_128(digits, (~(<uint128>unscaled) + 1) if unscaled < 0 else <uint128>unscaled)
        return decimal_from_digits(digits, count, unscaled < 0, scale, flags)
    # More than 38 digits, Decimal makes them from an int faster than from a text
    number = acsylla_varint_as_int(varint, varint_size)
    if not flags & NATIVE_TYPES:
        return Decimal(number).scaleb(-scale, DECIMAL_EXACT)
    try:
        text = str(-number if number < 0 else number)
    except ValueError:
        # More digits than str() of an int makes, sys.get_int_max_str_digits()
        return str(Decimal(number).scaleb(-scale, DECIMAL_EXACT))
    text_digits = PyUnicode_AsUTF8AndSize(text, &count)
    return decimal_from_digits(text_digits, count, number < 0, scale, flags)


cdef inline object _custom(const CassValue* cass_value, int8_t flags):
    """ Returns the list of the items of a vector column, the bytes of the value of another custom type and the bytes
    of a vector with legacy_types, as acsylla 1.x did.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef size_t size = 0
    cdef const cass_byte_t* data = NULL
    cdef CassError error

    error = cass_value_get_bytes(cass_value, &data, &size)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    if flags & LEGACY_TYPES:
        return data[:size]
    vector = vector_type(cass_value_data_type(cass_value))
    if vector is None:
        return data[:size]
    if size == 0:
        # An empty value
        return None
    return read_vector(data, size, vector, flags)


cdef inline object _varint(const CassValue* cass_value, int8_t flags):
    """ Returns the int of a varint column, its two's complement bytes with legacy_types as acsylla 1.x did.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef size_t size = 0
    cdef const cass_byte_t* varint = NULL
    cdef int128 value
    cdef CassError error

    error = cass_value_get_bytes(cass_value, &varint, &size)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    if flags & LEGACY_TYPES:
        return varint[:size]
    if size == 0:
        # An empty value
        return None
    if size <= 8:
        varint_as_int128(varint, size, &value)
        return PyLong_FromLongLong(<long long>value)
    return acsylla_varint_as_int(varint, size)


cdef inline object _bool(const CassValue* cass_value):
    """ Returns the bool value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_bool_t output
    cdef CassError error

    error = cass_value_get_bool(cass_value, <cass_bool_t*> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    if output == cass_true:
        return True
    else:
        return False


cdef inline object _string(const CassValue* cass_value):
    """ Returns the string value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef Py_ssize_t length = 0
    cdef char* output = NULL
    cdef CassError error
    cdef bytes string

    error = cass_value_get_string(cass_value,<const char**> &output, <size_t*> &length)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    # This pointer does not need to be free up since its an
    # slice of the buffer kept by the Cassandra driver and related to
    # the result. When the result is free up all the space will be free up.
    string = output[:length]
    return string.decode()


cdef inline object _bytes(const CassValue* cass_value):
    """ Returns the bytes value of a column.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef Py_ssize_t length = 0
    cdef cass_byte_t* output = NULL
    cdef CassError error
    cdef bytes bytes_

    error = cass_value_get_bytes(cass_value, <const cass_byte_t**> &output, <size_t*> &length)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    # This pointer does not need to be free up since its an
    # slice of the buffer kept by the Cassandra driver and related to
    # the result. When the result is free up all the space will be free up.
    bytes_ = output[:length]
    return bytes_


cdef inline object _inet(const CassValue* cass_value, int8_t flags):
    """ Returns the IPv4Address or IPv6Address of an inet column, its str with native_types or legacy_types.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef CassInet output
    cdef char address[CASS_INET_STRING_LENGTH]
    cdef CassError error
    error = cass_value_get_inet(cass_value, <CassInet*>&output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    if flags & (NATIVE_TYPES | LEGACY_TYPES):
        cass_inet_string(output, <char*>&address)
        return address.decode()
    if output.address_length == 4:
        number = PyLong_FromUnsignedLong((<unsigned long>output.address[0] << 24) | (output.address[1] << 16)
                                         | (output.address[2] << 8) | output.address[3])
        if IPV4_IP_OFFSET >= 0:
            return acsylla_new_with_slots(IPv4Address, number, IPV4_IP_OFFSET, None, -1)
        return IPv4Address(number)
    number = acsylla_unsigned_int(output.address, 16)
    if IPV6_IP_OFFSET >= 0:
        return acsylla_new_with_slots(IPv6Address, number, IPV6_IP_OFFSET, None, IPV6_SCOPE_ID_OFFSET)
    return IPv6Address(number)


@cython.cdivision(True)
cdef inline Py_ssize_t write_padded(char* buffer, uint64_t value, Py_ssize_t width):
    """Writes the digits of `value` with leading zeros up to `width` digits. Returns their number."""
    cdef char digits[20]
    cdef Py_ssize_t count = write_digits(digits, value), length = 0
    while length + count < width:
        buffer[length] = b"0"
        length += 1
    memcpy(buffer + length, digits, count)
    return length + count


cdef inline Py_ssize_t write_date(char* buffer, int year, unsigned month, unsigned day):
    """YYYY-MM-DD as toJson() of CQL: at least 4 digits of the year, a sign before the year 0. Returns its length."""
    cdef Py_ssize_t length = 0
    if year < 0:
        buffer[0] = b"-"
        length = 1
    length += write_padded(buffer + length, <uint64_t>(-(<long long>year) if year < 0 else year), 4)
    buffer[length] = b"-"
    length += 1
    length += write_padded(buffer + length, month, 2)
    buffer[length] = b"-"
    length += 1
    length += write_padded(buffer + length, day, 2)
    return length


cdef inline Py_ssize_t write_clock(char* buffer, long long hour, long long minute, long long second, long long fraction,
                                   Py_ssize_t fraction_digits):
    """HH:MM:SS.fraction, with `fraction_digits` digits. Returns its length."""
    cdef Py_ssize_t length = write_padded(buffer, hour, 2)
    buffer[length] = b":"
    length += 1
    length += write_padded(buffer + length, minute, 2)
    buffer[length] = b":"
    length += 1
    length += write_padded(buffer + length, second, 2)
    buffer[length] = b"."
    length += 1
    length += write_padded(buffer + length, fraction, fraction_digits)
    return length


cdef inline object _date(const CassValue* cass_value, int8_t flags):
    """ Returns the date of a date column, its YYYY-MM-DD with native_types in all the years of CQL.

    Raises a derived `CassException` if the value can not be retrieved, ValueError for a year out of 1..9999"""
    cdef cass_uint32_t output
    cdef CassError error
    cdef int year
    cdef unsigned month, day
    cdef char buffer[24]

    error = cass_value_get_uint32(cass_value, <cass_uint32_t *> &output)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    # The value is 2^31 + the days since 1970-01-01
    civil_from_days(<long long>output - 2147483648LL, &year, &month, &day)
    if flags & NATIVE_TYPES or year < 1 or year > 9999:
        text = PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, buffer, write_date(buffer, year, month, day))
        if flags & NATIVE_TYPES:
            return text
        raise ValueError(f"the date {text} is out of the years 1..9999 of Python, native_types=True reads it as a str")
    return date_new(year, month, day)


@cython.cdivision(True)
cdef inline object _time(const CassValue* cass_value, int8_t flags):
    """ Returns the time of a time column to microseconds, HH:MM:SS.nnnnnnnnn with native_types.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int64_t nanoseconds
    cdef long long hour, minute, second, fraction
    cdef CassError error
    cdef char buffer[24]

    error = cass_value_get_int64(cass_value, <cass_int64_t *> &nanoseconds)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)
    if nanoseconds < 0 or nanoseconds >= 86400000000000LL:
        raise ValueError(f"the time of {nanoseconds} nanoseconds is out of a day")
    hour = nanoseconds // 3600000000000LL
    minute = nanoseconds // 60000000000LL % 60
    second = nanoseconds // 1000000000 % 60
    fraction = nanoseconds % 1000000000
    if flags & NATIVE_TYPES:
        return PyUnicode_FromKindAndData(
            PyUnicode_1BYTE_KIND, buffer, write_clock(buffer, hour, minute, second, fraction, 9))
    return time_new(hour, minute, second, fraction // 1000, None)


cdef inline object _timestamp(const CassValue* cass_value, int8_t flags):
    """ Returns the datetime in UTC of a timestamp column, its YYYY-MM-DD HH:MM:SS.mmmZ with native_types in all the
    years of CQL.

    Raises a derived `CassException` if the value can not be retrieved, ValueError for a year out of 1..9999"""
    cdef cass_int64_t milliseconds
    cdef long long days, of_day
    cdef CassError error
    cdef int year
    cdef unsigned month, day
    cdef char buffer[48]
    cdef Py_ssize_t length

    error = cass_value_get_int64(cass_value, <cass_int64_t *> &milliseconds)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    # Floor division, the milliseconds before 1970 belong to the days before, in integers: a double of seconds loses
    # the last millisecond of the year 9999
    days = milliseconds // 86400000
    of_day = milliseconds - days * 86400000
    civil_from_days(days, &year, &month, &day)
    if flags & NATIVE_TYPES or year < 1 or year > 9999:
        length = write_date(buffer, year, month, day)
        buffer[length] = b" "
        length += 1
        length += write_clock(buffer + length, of_day // 3600000, of_day // 60000 % 60, of_day // 1000 % 60,
                              of_day % 1000, 3)
        buffer[length] = b"Z"
        text = PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, buffer, length + 1)
        if flags & NATIVE_TYPES:
            return text
        raise ValueError(
            f"the timestamp {text} is out of the years 1..9999 of Python, native_types=True reads it as a str")
    return datetime_new(year, month, day, of_day // 3600000, of_day // 60000 % 60, of_day // 1000 % 60,
                        of_day % 1000 * 1000, get_utc())


cdef inline Py_ssize_t write_unit(char* buffer, Py_ssize_t length, uint64_t value, const char* unit):
    """Writes <value><unit> after `length` when the value is not 0. Returns the new length."""
    cdef Py_ssize_t i = 0
    if value == 0:
        return length
    length += write_digits(buffer + length, value)
    while unit[i]:
        buffer[length] = unit[i]
        length += 1
        i += 1
    return length


@cython.cdivision(True)
cdef object duration_literal(long long months, long long days, long long nanoseconds, bint legacy):
    """The CQL literal of a duration, as '-1y2mo3d4h5m6s7ms8us9ns'. A zero duration is '0s', '' with legacy as
    acsylla 1.x wrote it."""
    cdef char buffer[160]
    cdef Py_ssize_t length = 0
    cdef uint64_t month_count = (~(<uint64_t>months) + 1) if months < 0 else <uint64_t>months
    cdef uint64_t day_count = (~(<uint64_t>days) + 1) if days < 0 else <uint64_t>days
    cdef uint64_t n = (~(<uint64_t>nanoseconds) + 1) if nanoseconds < 0 else <uint64_t>nanoseconds
    if months < 0 or days < 0 or nanoseconds < 0:
        buffer[0] = b"-"
        length = 1
    length = write_unit(buffer, length, month_count / 12, "y")
    length = write_unit(buffer, length, month_count % 12, "mo")
    length = write_unit(buffer, length, day_count, "d")
    length = write_unit(buffer, length, n / 3600000000000ULL, "h")
    length = write_unit(buffer, length, n / 60000000000ULL % 60, "m")
    length = write_unit(buffer, length, n / 1000000000ULL % 60, "s")
    length = write_unit(buffer, length, n / 1000000 % 1000, "ms")
    length = write_unit(buffer, length, n / 1000 % 1000, "us")
    length = write_unit(buffer, length, n % 1000, "ns")
    if length == 0:
        return "" if legacy else "0s"
    return PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, buffer, length)


cdef inline object _duration(const CassValue* cass_value, int8_t flags):
    """ Returns the Duration of a duration column, its CQL literal with native_types. With legacy_types its CQL literal
    and the tuple (months, days, nanoseconds) with native_types, as acsylla 1.x did.

    Raises a derived `CassException` if the value can not be retrieved"""
    cdef cass_int32_t months
    cdef cass_int32_t days
    cdef cass_int64_t nanos
    cdef CassError error

    error = cass_value_get_duration(cass_value, <cass_int32_t*>&months, <cass_int32_t*>&days, <cass_int64_t *>&nanos)
    if error == CASS_ERROR_LIB_NULL_VALUE:
        return None
    else:
        raise_if_error(error)

    if flags & LEGACY_TYPES:
        if flags & NATIVE_TYPES:
            return months, days, nanos
        return duration_literal(months, days, nanos, True)
    if flags & NATIVE_TYPES:
        return duration_literal(months, days, nanos, False)
    return Duration.new_(months, days, nanos)


cdef inline object _map(const CassValue* cass_value, int8_t flags):
    cdef const CassValue* key
    cdef const CassValue* value
    cdef CassIterator* iterator = cass_iterator_from_map(cass_value);
    data = {}
    if iterator == NULL:
        return None
    while cass_iterator_next(iterator) == cass_true:
        key = cass_iterator_get_map_key(iterator)
        value = cass_iterator_get_map_value(iterator)
        data[get_cass_value(key, flags)] = get_cass_value(value, flags)
    cass_iterator_free(iterator)
    return data


cdef inline object _set(const CassValue* cass_value, int8_t flags):
    cdef const CassValue* value
    cdef CassIterator* iterator = cass_iterator_from_collection(cass_value);
    data = set()
    if iterator == NULL:
        return None
    while cass_iterator_next(iterator) == cass_true:
        value = cass_iterator_get_value(iterator)
        data.add(get_cass_value(value, flags))
    cass_iterator_free(iterator)
    return data


cdef inline object _list(const CassValue* cass_value, int8_t flags):
    cdef const CassValue* value
    cdef CassIterator* iterator = cass_iterator_from_collection(cass_value);
    data = list()
    if iterator == NULL:
        return None

    while cass_iterator_next(iterator) == cass_true:
        value = cass_iterator_get_value(iterator)
        data.append(get_cass_value(value, flags))
    cass_iterator_free(iterator)
    return data


cdef inline object _tuple(const CassValue* cass_value, int8_t flags):
    cdef const CassValue* value
    cdef CassIterator* iterator = cass_iterator_from_tuple(cass_value);
    data = list()
    if iterator == NULL:
        return None
    while cass_iterator_next(iterator) == cass_true:
        value = cass_iterator_get_value(iterator)
        data.append(get_cass_value(value, flags))
    cass_iterator_free(iterator)
    return tuple(data)


cdef inline object _udt(const CassValue* cass_value, int8_t flags):
    cdef const char* field_name
    cdef size_t field_name_length
    cdef const CassValue* field_value
    cdef CassIterator* iterator = cass_iterator_fields_from_user_type(cass_value);
    data = {}
    while cass_iterator_next(iterator) == cass_true:
        cass_iterator_get_user_type_field_name(iterator, &field_name, &field_name_length)
        field_value = cass_iterator_get_user_type_field_value(iterator)
        data[field_name[:field_name_length].decode()] = get_cass_value(field_value, flags)
    cass_iterator_free(iterator)
    return data
