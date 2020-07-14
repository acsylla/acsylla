import pytest
from acsylla import Statement
from acsylla.errors import ColumnNotFound


pytestmark = pytest.mark.asyncio


class TestResult:
    async def test_result_no_row(self, session, id_generation):
        id_ = next(id_generation)

        # try to read a none inserted value
        statement = Statement(
            "SELECT id, value FROM test WHERE id =" +
            str(id_)
        )
        result = await session.execute(statement)

        assert result.count() == 0
        assert result.first() is None

    async def test_result_one_row(self, session, id_generation):
        id_ = next(id_generation)
        value = 100

        # insert a new value into the table
        statement = Statement(
            "INSERT INTO test (id, value) values(" +
            str(id_) +
            ', ' +
            str(value) +
            ')'
        )
        await session.execute(statement)

        # read the new inserted value
        statement = Statement(
            "SELECT id, value FROM test WHERE id =" +
            str(id_)
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
        statement = Statement(
            "INSERT INTO test (id, value) values(" +
            str(id_) +
            ', ' +
            str(value) +
            ')'
        )
        await session.execute(statement)

        # read the new inserted value
        statement = Statement(
            "SELECT id, value FROM test WHERE id =" +
            str(id_)
        )
        result = await session.execute(statement)

        row = result.first()
        with pytest.raises(ColumnNotFound):
            row.column_by_name(b"invalid_column_name")

    async def test_result_multiple_rows(self, session, id_generation):
        total_rows = 100
        value = 33

        statement = Statement(
            "INSERT INTO test (id, value) values(?, ?)",
            parameters=2
        )

        statement.bind_int(value, 1)

        ids = [next(id_generation) for i in range(total_rows)]

        # write results 
        for id_ in ids:
            statement.bind_int(id_, 0)
            await session.execute(statement)

        # read all results
        statement = Statement(
            "SELECT id, value FROM test WHERE id >= ? and id <= ? ALLOW FILTERING",
            parameters=2
        )
        statement.bind_int(ids[0], 0)
        statement.bind_int(ids[-1], 1)
        result = await session.execute(statement)

        assert result.count() == total_rows
        assert result.column_count() == 2

        ids_returned = [row.column_by_name(b"id").int() for row in result.all()]
        values_returned = [row.column_by_name(b"value").int() for row in result.all()]

        # values returned are unsorted
        assert sorted(ids_returned) == sorted(ids)
        assert values_returned == [value] * total_rows

    async def test_result_multiple_no_rows(self, session, id_generation):
        total_rows = 100
        ids = [next(id_generation) for i in range(total_rows)]

        # try to read unavailable results
        statement = Statement(
            "SELECT id, value FROM test WHERE id >= ? and id <= ? ALLOW FILTERING",
            parameters=2
        )
        statement.bind_int(ids[0], 0)
        statement.bind_int(ids[-1], 1)
        result = await session.execute(statement)

        assert result.count() == 0

        ids_returned = [row.column_by_name(b"id").int() for row in result.all()]
        values_returned = [row.column_by_name(b"value").int() for row in result.all()]

        assert ids_returned == []
        assert values_returned == []

    @pytest.mark.xfail
    async def test_result_types_supported(self, session, id_generation):
        raise Exception("TODO")

    @pytest.mark.xfail
    async def test_result_more_pages(self, session, id_generation):
        raise Exception("TODO")
