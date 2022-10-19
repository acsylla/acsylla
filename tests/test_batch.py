from acsylla import create_batch_counter
from acsylla import create_batch_logged
from acsylla import create_batch_unlogged
from acsylla import create_statement

import pytest

pytestmark = pytest.mark.asyncio


class TestBatch:
    @pytest.fixture(params=["none_prepared", "prepared"])
    async def statement(self, request, session):
        statement_str = "INSERT INTO test (id, value) values " + "(?, ?)"
        if request.param == "none_prepared":
            statement_ = create_statement(statement_str, parameters=2)
        elif request.param == "prepared":
            prepared = await session.create_prepared(statement_str)
            statement_ = prepared.bind()
        else:
            raise ValueError()

        return statement_

    @pytest.fixture(params=["logged", "unlogged"])
    async def batch(self, request, session):
        if request.param == "logged":
            return create_batch_logged()
        elif request.param == "unlogged":
            return create_batch_unlogged()
        else:
            raise ValueError()

    def test_create_batch_logged(self):
        batch = create_batch_logged()
        assert batch is not None

    def test_create_batch_unlogged(self):
        batch = create_batch_unlogged()
        assert batch is not None

    def test_create_batch_logged_with_timeout__and_profile(self):
        batch = create_batch_logged(timeout=1.0, execution_profile="")
        batch.set_execution_profile("")
        assert batch is not None

    def test_create_batch_unlogged_with_timeout_and_profile(self):
        batch = create_batch_unlogged(timeout=1.0, execution_profile="")
        batch.set_execution_profile("")
        assert batch is not None

    def test_create_batch_counter(self):
        batch = create_batch_counter()
        assert batch is not None

    def test_create_batch_counter_with_timeout_and_profile(self):
        batch = create_batch_counter(timeout=1.0, execution_profile="")
        batch.set_execution_profile("")
        assert batch is not None

    def test_add_statement(self, batch, statement):
        # just check that does not raise any error
        batch.add_statement(statement)
