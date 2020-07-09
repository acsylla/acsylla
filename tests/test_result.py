import pytest

from acsylla.errors import ColumnNotFound


pytestmark = pytest.mark.asyncio


class TestResult:
    async def test_result_no_row(self, session, id_generation):
        id_ = next(id_generation)

        # try to read a none inserted value
        statement = (
            b"SELECT id, value FROM test WHERE id =" +
            str(id_).encode()
        )
        result = await session.execute(statement)

        assert result.count() == 0
        assert result.first() is None

    async def test_result_one_row(self, session, id_generation):
        id_ = next(id_generation)
        value = 100

        # insert a new value into the table
        statement = (
            b"INSERT INTO test (id, value) values(" +
            str(id_).encode() +
            b', ' +
            str(value).encode() +
            b')'
        )
        await session.execute(statement)

        # read the new inserted value
        statement = (
            b"SELECT id, value FROM test WHERE id =" +
            str(id_).encode()
        )
        result = await session.execute(statement)

        assert result.count() == 1
        assert result.column_count() == 2

        row = result.first()

        # check that the columns have the expected values
        assert row.column_by_name(b"id").int() == id_
        assert row.column_by_name(b"value").int() == value

    async def test_result_invalid_column_name(self, session, id_generation):
        id_ = next(id_generation)
        value = 100

        # insert a new value into the table
        statement = (
            b"INSERT INTO test (id, value) values(" +
            str(id_).encode() +
            b', ' +
            str(value).encode() +
            b')'
        )
        await session.execute(statement)

        # read the new inserted value
        statement = (
            b"SELECT id, value FROM test WHERE id =" +
            str(id_).encode()
        )
        result = await session.execute(statement)

        row = result.first()
        with pytest.raises(ColumnNotFound):
            row.column_by_name(b"invalid_column_name")

    @pytest.mark.xfail
    async def test_result_multiple_rows(self, session, id_generation):
        raise Exception("TODO")

    @pytest.mark.xfail
    async def test_result_types_supported(self, session, id_generation):
        raise Exception("TODO")

    @pytest.mark.xfail
    async def test_result_more_pages(self, session, id_generation):
        raise Exception("TODO")
