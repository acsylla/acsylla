from acsylla import Consistency
from acsylla import create_batch_counter
from acsylla import create_batch_logged
from acsylla import create_batch_unlogged
from acsylla import create_statement

import pytest
import time

# pytestmark = pytest.mark.asyncio


class TestBatch:
    @pytest.fixture(scope="class", autouse=True, params=["none_prepared", "prepared"])
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

    @pytest.fixture(scope="class", autouse=True, params=["logged", "unlogged", "counter"])
    async def batch(self, request, session):
        if request.param == "logged":
            return create_batch_logged()
        elif request.param == "unlogged":
            return create_batch_unlogged()
        elif request.param == "counter":
            return create_batch_counter()
        else:
            raise ValueError()

    def test_create_batch_logged(self):
        batch = create_batch_logged()
        assert batch is not None

    def test_create_batch_unlogged(self):
        batch = create_batch_unlogged()
        assert batch is not None

    def test_create_batch_logged_with_timeout_and_profile(self):
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

    @pytest.mark.parametrize(
        "consistency",
        [
            Consistency.ANY,
            Consistency.ONE,
            Consistency.TWO,
            Consistency.THREE,
            Consistency.QUORUM,
            Consistency.ALL,
            Consistency.LOCAL_QUORUM,
            Consistency.EACH_QUORUM,
            Consistency.SERIAL,
            Consistency.LOCAL_SERIAL,
            Consistency.LOCAL_ONE,
        ],
    )
    def test_set_consistency(self, consistency):
        batch = create_batch_logged()
        batch.set_consistency(consistency)
        batch = create_batch_unlogged()
        batch.set_consistency(consistency)
        batch = create_batch_counter()
        batch.set_consistency(consistency)

    @pytest.mark.parametrize(
        "serial_consistency",
        [Consistency.SERIAL, Consistency.LOCAL_SERIAL],
    )
    def test_set_serial_consistency(self, serial_consistency):
        batch = create_batch_logged()
        batch.set_consistency(serial_consistency)
        batch = create_batch_unlogged()
        batch.set_consistency(serial_consistency)
        batch = create_batch_counter()
        batch.set_consistency(serial_consistency)

    def test_set_timestamp(self, batch):
        batch.set_timestamp(time.time())
        batch.set_timestamp(None)

    def test_set_is_idempotent(self, batch):
        batch.set_is_idempotent(True)
        batch.set_is_idempotent(False)
        batch.set_is_idempotent(None)

    async def test_set_retry_policy(self, batch):
        batch.set_retry_policy("default")
        batch.set_retry_policy("fallthrough")
        batch.set_retry_policy("default", retry_policy_logging=True)
        batch.set_retry_policy("fallthrough", retry_policy_logging=True)
        batch.set_retry_policy(None)

    async def test_set_tracing(self, batch):
        batch.set_tracing(True)
        batch.set_tracing(False)
        batch.set_tracing(None)
