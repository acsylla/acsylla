from acsylla import create_statement
from acsylla.errors import ColumnNotFound

import pytest

pytestmark = pytest.mark.asyncio


class TestResult:
    async def _build_statement(self, session, type_, statement_str, parameters, page_size=None, page_state=None):
        if type_ == "none_prepared":
            statement_ = create_statement(
                statement_str, parameters=parameters, page_size=page_size, page_state=page_state
            )
        elif type_ == "prepared":
            prepared = await session.create_prepared(statement_str)
            statement_ = prepared.bind(page_size=page_size, page_state=page_state)
        else:
            raise ValueError(type_)
        return statement_

    @pytest.fixture(params=["none_prepared", "prepared"])
    async def insert_statement(self, request, session):
        statement_str = "INSERT INTO test (id, value) values(?, ?)"
        return await self._build_statement(session, request.param, statement_str, 2)

    @pytest.fixture(params=["none_prepared", "prepared"])
    async def select_statement(self, request, session):
        statement_str = "SELECT id, value FROM test WHERE id = ?"
        return await self._build_statement(session, request.param, statement_str, 1)

    @pytest.fixture(params=["none_prepared", "prepared"])
    async def select_filter_statement(self, request, session):
        statement_str = "SELECT id, value FROM test WHERE id >= :min and id <= :max ALLOW FILTERING"
        return await self._build_statement(session, request.param, statement_str, 2)

    async def test_result_no_row(self, session, select_statement, id_generation):
        id_ = next(id_generation)

        # try to read a none inserted value
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        assert result.count() == 0
        assert result.first() is None

    async def test_result_one_row(self, session, insert_statement, select_statement, id_generation):
        id_ = next(id_generation)
        value = 100

        # insert a new value into the table
        insert_statement.bind_list([id_, value])
        await session.execute(insert_statement)

        # read the new inserted value
        select_statement.bind(0, id_)
        result = await session.execute(select_statement)

        assert result.count() == 1
        assert result.column_count() == 2

        row = result.first()

        # check that the columns have the expected values
        assert row.column_by_name("id").value() == id_
        assert row.column_by_name("value").value() == value

    async def test_result_invalid_column_name(self, session, id_generation):
        id_ = next(id_generation)
        value = 100

        # insert a new value into the table
        statement = create_statement("INSERT INTO test (id, value) values(" + str(id_) + ", " + str(value) + ")")
        await session.execute(statement)

        # read the new inserted value
        statement = create_statement("SELECT id, value FROM test WHERE id =" + str(id_))
        result = await session.execute(statement)

        row = result.first()
        with pytest.raises(ColumnNotFound):
            row.column_by_name("invalid_column_name")

    async def test_result_multiple_rows(self, session, insert_statement, select_filter_statement, id_generation):
        total_rows = 100
        value = 33

        insert_statement.bind(1, value)

        ids = [next(id_generation) for i in range(total_rows)]

        # write results
        for id_ in ids:
            insert_statement.bind(0, id_)
            await session.execute(insert_statement)

        # read all results
        select_filter_statement.bind_list([ids[0], ids[-1]])
        result = await session.execute(select_filter_statement)

        assert result.count() == total_rows
        assert result.column_count() == 2

        ids_returned = [row.column_by_name("id").value() for row in result.all()]
        values_returned = [row.column_by_name("value").value() for row in result.all()]

        # values returned are unsorted
        assert sorted(ids_returned) == sorted(ids)
        assert values_returned == [value] * total_rows

    async def test_result_multiple_no_rows(self, session, id_generation, select_filter_statement):
        total_rows = 100
        ids = [next(id_generation) for i in range(total_rows)]

        # try to read unavailable results
        select_filter_statement.bind_list([ids[0], ids[-1]])
        result = await session.execute(select_filter_statement)

        assert result.count() == 0

        ids_returned = [row.column_by_name("id").int() for row in result.all()]
        values_returned = [row.column_by_name("value").int() for row in result.all()]

        assert ids_returned == []
        assert values_returned == []

    @pytest.mark.parametrize(
        "page_size,pages_fetched_expected",
        [
            # Check that when page size is disabled, only one page is fetched
            (None, 1),
            # When number of results returned do not match with the page size,
            # pages returned are optimal
            (75, 2),
            # When number of results returned match with the page size driver
            # forces us to make a new fetch returning the last one zero results
            (100, 2),
            (25, 5),
            (50, 3),
        ],
    )
    @pytest.mark.parametrize("type_", ["prepared", "none_prepared"])
    async def test_result_paging(self, session, id_generation, type_, page_size, pages_fetched_expected):
        total_rows = 100
        value = 33
        insert_statement = "INSERT INTO test (id, value) values(?, ?)"
        select_statement = "SELECT id, value FROM test WHERE id >= :min and id <= :max ALLOW FILTERING"

        statement = create_statement(insert_statement, parameters=2)
        statement.bind(1, value)
        ids = [next(id_generation) for i in range(total_rows)]
        # write results
        for id_ in ids:
            statement.bind(0, id_)
            await session.execute(statement)

        # read all results using pagination
        page_state = None
        pages_fetched = 0
        while True:
            statement = await self._build_statement(
                session, type_, select_statement, 2, page_size=page_size, page_state=page_state
            )
            statement.bind_list([ids[0], ids[-1]])
            result = await session.execute(statement)

            pages_fetched += 1

            if not result.has_more_pages():
                break

            page_state = result.page_state()

        assert pages_fetched == pages_fetched_expected
