import pytest

from acsylla import create_statement


pytestmark = pytest.mark.asyncio


class TestStatement:

    OUT_OF_BAND_PARAMETER = 10

    @pytest.fixture(params=["none_prepared", "prepared"])
    async def statement(self, request, session):
        statement_str = (
            "INSERT INTO test (id, value, value_int, value_float, value_bool, value_text, value_blob) values " +
            "(?, ?, ?, ?, ?, ?, ?)"
        )
        if request.param == "none_prepared":
            statement_ = create_statement(statement_str, parameters=7)
        elif request.param == "prepared":
            prepared = await session.create_prepared(statement_str)
            statement_ = prepared.bind()
        else:
            raise ValueError()

        return statement_

    def test_bind_null(self, statement):
        statement.bind_null(1)

    def test_bind_null_invalid_index(self, statement):
        with pytest.raises(ValueError):
            statement.bind_null(TestStatement.OUT_OF_BAND_PARAMETER)

    def test_bind_int(self, statement):
        statement.bind_int(10, 2)

    def test_bind_int_invalid_index(self, statement):
        with pytest.raises(ValueError):
            statement.bind_int(10, TestStatement.OUT_OF_BAND_PARAMETER)

    def test_bind_float(self, statement):
        statement.bind_float(10.0, 3)

    def test_bind_float_invalid_index(self, statement):
        with pytest.raises(ValueError):
            statement.bind_float(10.0, TestStatement.OUT_OF_BAND_PARAMETER)

    def test_bind_bool(self, statement):
        statement.bind_bool(True, 4)

    def test_bind_bool_invalid_object(self, statement):
        with pytest.raises(ValueError):
            statement.bind_bool("", 4)

    def test_bind_bool_invalid_index(self, statement):
        with pytest.raises(ValueError):
            statement.bind_bool(True, TestStatement.OUT_OF_BAND_PARAMETER)

    def test_bind_string(self, statement):
        statement.bind_string("acsylla", 5)

    def test_bind_string_invalid_index(self, statement):
        with pytest.raises(ValueError):
            statement.bind_string("acsylla", TestStatement.OUT_OF_BAND_PARAMETER)

    def test_bind_bytes(self, statement):
        statement.bind_bytes(b"acsylla", 6)

    def test_bind_bytes_invalid_index(self, statement):
        with pytest.raises(ValueError):
            statement.bind_bytes(b"acsylla", TestStatement.OUT_OF_BAND_PARAMETER)
