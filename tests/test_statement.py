import pytest

from acsylla import Statement


pytestmark = pytest.mark.asyncio


class TestStatement:

    def test_bind_null(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        statement.bind_null(0)

    def test_bind_null_invalid_index(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        with pytest.raises(ValueError):
            statement.bind_null(1)

    def test_bind_int(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        statement.bind_int(10, 0)

    def test_bind_int_invalid_index(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        with pytest.raises(ValueError):
            statement.bind_int(10, 1)

    def test_bind_float(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        statement.bind_int(10.0, 0)

    def test_bind_float_invalid_index(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        with pytest.raises(ValueError):
            statement.bind_float(10.0, 1)

    def test_bind_bool(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        statement.bind_bool(True, 0)

    def test_bind_bool_invalid_object(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        with pytest.raises(ValueError):
            statement.bind_bool("", 0)

    def test_bind_bool_invalid_index(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        with pytest.raises(ValueError):
            statement.bind_bool(True, 1)

    def test_bind_string(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        statement.bind_string("acsylla", 0)

    def test_bind_string_invalid_index(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        with pytest.raises(ValueError):
            statement.bind_string("acsylla", 1)

    def test_bind_bytes(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        statement.bind_bytes(b"acsylla", 0)

    def test_bind_bytes_invalid_index(self):
        statement = Statement("SELECT id FROM test WHERE id = ?", parameters=1)
        with pytest.raises(ValueError):
            statement.bind_bytes(b"acsylla", 1)
