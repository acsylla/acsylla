# A vector of CQL is a custom type for the driver, its class name tells its items: VectorType(FloatType, 3). Its value
# is the items one after another, the items of a variable size each after its size in an unsigned vint
from cpython.buffer cimport PyBUF_C_CONTIGUOUS
from cpython.buffer cimport PyBUF_FORMAT
from cpython.buffer cimport PyBuffer_Release
from cpython.buffer cimport PyObject_CheckBuffer
from cpython.buffer cimport PyObject_GetBuffer
from cpython.bytes cimport PyBytes_AS_STRING
from cpython.bytes cimport PyBytes_FromStringAndSize
from cpython.float cimport PyFloat_AsDouble
from cpython.float cimport PyFloat_FromDouble
from cpython.list cimport PyList_New
from cpython.list cimport PyList_SET_ITEM
from cpython.long cimport PyLong_AsLongLong
from cpython.long cimport PyLong_FromLong
from cpython.ref cimport Py_INCREF
from cpython.sequence cimport PySequence_Fast
from cpython.sequence cimport PySequence_Fast_GET_ITEM
from cpython.sequence cimport PySequence_Fast_GET_SIZE
from libc.string cimport memcpy

cdef extern from *:
    """
    /* Copies count items of size 4 or 8 with their bytes reversed, a loop the compiler makes vector instructions of */
    static void acsylla_copy_swapped(char* output, const char* input, Py_ssize_t count, Py_ssize_t size) {
        Py_ssize_t i;
        if (size == 4) {
            for (i = 0; i < count; i++) {
                uint32_t item;
                memcpy(&item, input + i * 4, 4);
                item = __builtin_bswap32(item);
                memcpy(output + i * 4, &item, 4);
            }
        } else {
            for (i = 0; i < count; i++) {
                uint64_t item;
                memcpy(&item, input + i * 8, 8);
                item = __builtin_bswap64(item);
                memcpy(output + i * 8, &item, 8);
            }
        }
    }
    """
    void acsylla_copy_swapped(char* output, const char* input, Py_ssize_t count, Py_ssize_t size)


cdef enum VectorItem:
    VECTOR_FLOAT
    VECTOR_DOUBLE
    VECTOR_INT
    VECTOR_BIGINT
    VECTOR_SMALLINT
    VECTOR_TINYINT
    VECTOR_BOOLEAN
    VECTOR_UUID
    VECTOR_TEXT
    VECTOR_BLOB
    VECTOR_VARINT

# The class of an item -> its kind and size, 0 for a variable one. smallint and tinyint have a size before each, as
# Cassandra does not take their classes for ones of a fixed size
VECTOR_ITEMS = {
    "FloatType": (VECTOR_FLOAT, 4),
    "DoubleType": (VECTOR_DOUBLE, 8),
    "Int32Type": (VECTOR_INT, 4),
    "LongType": (VECTOR_BIGINT, 8),
    "ShortType": (VECTOR_SMALLINT, 0),
    "ByteType": (VECTOR_TINYINT, 0),
    "BooleanType": (VECTOR_BOOLEAN, 1),
    "UUIDType": (VECTOR_UUID, 16),
    "TimeUUIDType": (VECTOR_UUID, 16),
    "UTF8Type": (VECTOR_TEXT, 0),
    "AsciiType": (VECTOR_TEXT, 0),
    "BytesType": (VECTOR_BLOB, 0),
    "IntegerType": (VECTOR_VARINT, 0),
}
MARSHAL = "org.apache.cassandra.db.marshal."

# The class name of a custom type -> (kind, size, dimension) of a vector, None for another type or a vector of items
# acsylla does not read. One entry for a class name of the schema
cdef dict VECTOR_TYPES = {}


cdef object parse_vector_type(str name):
    if not name.startswith(MARSHAL + "VectorType(") or not name.endswith(")"):
        return None
    item, _, dimension = name[len(MARSHAL + "VectorType("):-1].rpartition(",")
    item = item.strip()
    if item.startswith(MARSHAL):
        item = item[len(MARSHAL):]
    kind = VECTOR_ITEMS.get(item)
    if kind is None:
        return None
    try:
        return kind + (int(dimension),)
    except ValueError:
        return None


cdef object vector_type(const CassDataType* data_type):
    """(kind, size, dimension) of a vector type, None for another custom type or no type."""
    cdef const char* name
    cdef size_t length
    if data_type == NULL or cass_data_type_class_name(data_type, &name, &length) != CASS_OK:
        return None
    key = name[:length]
    try:
        return VECTOR_TYPES[key]
    except KeyError:
        pass
    vector = parse_vector_type(key.decode("utf-8", "replace"))
    VECTOR_TYPES[key] = vector
    return vector


cdef inline uint64_t read_bits(const cass_byte_t* data, int size):
    cdef uint64_t bits = 0
    cdef int i
    for i in range(size):
        bits = (bits << 8) | data[i]
    return bits


cdef inline void write_bits(char* data, uint64_t bits, int size):
    cdef int i
    for i in range(size - 1, -1, -1):
        data[i] = <char>(bits & 0xFF)
        bits >>= 8


cdef object read_vector_item(const cass_byte_t* data, size_t size, int kind, int8_t flags):
    cdef uint64_t bits
    cdef uint32_t bits32
    cdef float single
    cdef double double_
    if kind == VECTOR_FLOAT:
        bits32 = <uint32_t>read_bits(data, 4)
        memcpy(&single, &bits32, 4)
        return PyFloat_FromDouble(single)
    if kind == VECTOR_DOUBLE:
        bits = read_bits(data, 8)
        memcpy(&double_, &bits, 8)
        return PyFloat_FromDouble(double_)
    if kind == VECTOR_INT:
        return PyLong_FromLong(<int32_t><uint32_t>read_bits(data, 4))
    if kind == VECTOR_BIGINT:
        return PyLong_FromLongLong(<int64_t>read_bits(data, 8))
    if kind == VECTOR_SMALLINT:
        if size != 2:
            raise ValueError(f"a smallint of {size} bytes in a vector")
        return PyLong_FromLong(<int16_t><uint16_t>read_bits(data, 2))
    if kind == VECTOR_TINYINT:
        if size != 1:
            raise ValueError(f"a tinyint of {size} bytes in a vector")
        return PyLong_FromLong(<int8_t><uint8_t>data[0])
    if kind == VECTOR_BOOLEAN:
        return data[0] != 0
    if kind == VECTOR_UUID:
        if flags & (NATIVE_TYPES | LEGACY_TYPES):
            return uuid_text(data)
        if UUID_INT_OFFSET >= 0:
            return acsylla_new_with_slots(UUID, acsylla_unsigned_int(data, 16), UUID_INT_OFFSET, UUID_UNKNOWN,
                                          UUID_IS_SAFE_OFFSET)
        return UUID(bytes=data[:16])
    if kind == VECTOR_TEXT:
        return (<const char*>data)[:size].decode("utf-8")
    if kind == VECTOR_BLOB:
        return data[:size]
    # VECTOR_VARINT
    if size == 0:
        return 0
    return acsylla_varint_as_int(data, size)


cdef object read_vector(const cass_byte_t* data, size_t size, tuple vector, int8_t flags):
    """The list of the items of a vector."""
    cdef int kind = vector[0]
    cdef size_t item_size = vector[1]
    cdef Py_ssize_t dimension = vector[2], i
    cdef size_t offset = 0, length
    cdef int extra, j
    cdef list items
    if item_size:
        if size != <size_t>dimension * item_size:
            raise ValueError(f"a vector of {dimension} items of {item_size} bytes in {size} bytes")
    items = PyList_New(dimension)
    for i in range(dimension):
        if item_size:
            length = item_size
        else:
            # The unsigned vint of the size: as many 1 bits before its first 0 bit as bytes after the first one
            if offset >= size:
                raise ValueError(f"a vector of {dimension} items ends after {i}")
            extra = 0
            while extra < 8 and data[offset] & (0x80 >> extra):
                extra += 1
            if offset + 1 + extra > size:
                raise ValueError(f"a vector of {dimension} items ends after {i}")
            length = data[offset] & (0xFF >> extra)
            for j in range(extra):
                offset += 1
                length = (length << 8) | data[offset]
            offset += 1
            if offset + length > size:
                raise ValueError(f"a vector of {dimension} items ends after {i}")
        item = read_vector_item(data + offset, length, kind, flags)
        offset += length
        Py_INCREF(item)
        PyList_SET_ITEM(items, i, item)
    if offset != size:
        raise ValueError(f"a vector of {dimension} items has {size - offset} bytes more")
    return items


cdef Py_ssize_t write_unsigned_vint(char* data, uint64_t value):
    """Writes the unsigned vint of `value` when data is not NULL. Returns its size."""
    cdef int extra = 0
    while extra < 8 and value >= (<uint64_t>1 << (7 * (extra + 1))):
        extra += 1
    if data != NULL:
        write_bits(data, value, extra + 1)
        if extra:
            data[0] = <char>((<unsigned char>data[0]) | (0xFF & ~(0xFF >> extra)))
    return extra + 1


cdef bytes vector_item_bytes(object item, int kind):
    """The bytes of an item of a variable size."""
    cdef long long number
    cdef char data[2]
    if kind == VECTOR_SMALLINT or kind == VECTOR_TINYINT:
        number = PyLong_AsLongLong(item)
        if kind == VECTOR_SMALLINT and not -32768 <= number <= 32767 or kind == VECTOR_TINYINT and not -128 <= number <= 127:
            raise OverflowError(f"The value {item} is out of the items of the vector")
        write_bits(data, <uint64_t>number, 2 if kind == VECTOR_SMALLINT else 1)
        return data[:2 if kind == VECTOR_SMALLINT else 1]
    if kind == VECTOR_TEXT:
        if not isinstance(item, str):
            raise ValueError(f'Value "{item}" is not a str for a vector of text')
        return (<str>item).encode("utf-8")
    if kind == VECTOR_BLOB:
        return as_blob(item)
    # VECTOR_VARINT
    return as_cass_varint(item)


cdef bint native_little_endian():
    cdef uint16_t probe = 1
    return (<unsigned char*>&probe)[0] == 1


cdef bint NATIVE_LITTLE_ENDIAN = native_little_endian()


cdef object write_vector_buffer(object value, int kind, Py_ssize_t item_size, Py_ssize_t dimension):
    """The bytes of a vector of numbers of a fixed size from a buffer of them, an array.array, a numpy array, a
    memoryview, without making an object of every item. None when the buffer does not hold them."""
    cdef Py_buffer view
    cdef const char* format
    cdef char order, letter
    cdef bytes output
    cdef char* data
    try:
        PyObject_GetBuffer(value, &view, PyBUF_C_CONTIGUOUS | PyBUF_FORMAT)
    except BufferError:
        # Not contiguous, a slice with a step
        return None
    try:
        if view.format == NULL:
            return None
        format = view.format
        order = b"@"
        if format[0] in b"@=<>!":
            order = format[0]
            format += 1
        letter = format[0]
        if view.ndim != 1 or view.itemsize != item_size or format[1] != 0:
            return None
        if kind == VECTOR_FLOAT and letter != b"f" or kind == VECTOR_DOUBLE and letter != b"d":
            return None
        if (kind == VECTOR_INT or kind == VECTOR_BIGINT) and letter not in b"ilq":
            return None
        if view.len != dimension * item_size:
            raise ValueError(f"A vector of {dimension} items, the value has {view.len // item_size}")
        output = PyBytes_FromStringAndSize(NULL, view.len)
        data = PyBytes_AS_STRING(output)
        if order == b">" or order == b"!" or (order != b"<" and not NATIVE_LITTLE_ENDIAN):
            # Big-endian already
            memcpy(data, view.buf, view.len)
        elif order == b"<" and not NATIVE_LITTLE_ENDIAN:
            return None
        else:
            # Little-endian items of this machine, each written big-endian
            acsylla_copy_swapped(data, <const char*>view.buf, dimension, item_size)
        return output
    finally:
        PyBuffer_Release(&view)


cdef bytes write_vector(object value, tuple vector):
    """The bytes of a vector of a sequence of its items."""
    cdef int kind = vector[0]
    cdef Py_ssize_t item_size = vector[1], dimension = vector[2], count, i, total = 0, offset = 0
    cdef bytes output
    cdef char* data
    cdef uint64_t bits
    cdef uint32_t bits32
    cdef float single
    cdef double double_
    cdef long long number
    cdef list parts
    cdef bytes uuid_bytes
    if item_size and kind in (VECTOR_FLOAT, VECTOR_DOUBLE, VECTOR_INT, VECTOR_BIGINT) and PyObject_CheckBuffer(value):
        buffered = write_vector_buffer(value, kind, item_size, dimension)
        if buffered is not None:
            return buffered
    items = PySequence_Fast(value, "A vector is a sequence of its items")
    count = PySequence_Fast_GET_SIZE(items)
    if count != dimension:
        raise ValueError(f"A vector of {dimension} items, the value has {count}")
    if item_size:
        output = PyBytes_FromStringAndSize(NULL, dimension * item_size)
        data = PyBytes_AS_STRING(output)
        for i in range(count):
            item = <object>PySequence_Fast_GET_ITEM(items, i)
            if kind == VECTOR_FLOAT:
                single = <float>PyFloat_AsDouble(item)
                memcpy(&bits32, &single, 4)
                bits = bits32
            elif kind == VECTOR_DOUBLE:
                double_ = PyFloat_AsDouble(item)
                memcpy(&bits, &double_, 8)
            elif kind == VECTOR_BOOLEAN:
                bits = 1 if as_bool(item) else 0
            elif kind == VECTOR_UUID:
                uuid_bytes = (item if isinstance(item, UUID) else UUID(item)).bytes
                memcpy(data + i * 16, PyBytes_AS_STRING(uuid_bytes), 16)
                continue
            else:
                number = PyLong_AsLongLong(item)
                if kind == VECTOR_INT and not -2147483648 <= number <= 2147483647:
                    raise OverflowError(f"The value {item} is out of the items of the vector")
                bits = <uint64_t>number
            write_bits(data + i * item_size, bits, item_size)
        return output
    parts = []
    for i in range(count):
        part = vector_item_bytes(<object>PySequence_Fast_GET_ITEM(items, i), kind)
        parts.append(part)
        total += write_unsigned_vint(NULL, len(part)) + len(part)
    output = PyBytes_FromStringAndSize(NULL, total)
    data = PyBytes_AS_STRING(output)
    for part in parts:
        offset += write_unsigned_vint(data + offset, len(part))
        memcpy(data + offset, PyBytes_AS_STRING(part), len(part))
        offset += len(part)
    return output


cdef bytes as_cass_custom(object value, const CassDataType* data_type):
    """The bytes of a value of a custom type: bytes as they are, a sequence of the items of a vector."""
    if isinstance(value, bytes):
        return value
    vector = vector_type(data_type)
    if vector is not None and not isinstance(value, (str, dict)):
        return write_vector(value, vector)
    raise ValueError(f'Value "{value}" is not bytes' + ("" if vector is None else " or the items of a vector"))
