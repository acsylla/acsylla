from acsylla import create_cluster
from acsylla import LogMessage

import functools
import io
import logging
import pytest

pytestmark = pytest.mark.asyncio


class TestLogging:
    async def test_logging_callback(self, host, keyspace):
        class Result:
            msg = None

        result = Result()

        def log_callback(msg, result=None):
            result.msg = msg

        callback = functools.partial(log_callback, result=result)
        cluster = create_cluster([host], log_level="INFO", logging_callback=callback)
        session = await cluster.create_session(keyspace=keyspace)
        await session.close()
        assert isinstance(result.msg, LogMessage)

    async def test_async_logging_callback(self, host, keyspace):
        class Result:
            msg = None

        result = Result()

        async def log_callback(msg, result=None):
            result.msg = msg

        callback = functools.partial(log_callback, result=result)
        cluster = create_cluster([host], log_level="INFO", logging_callback=callback)
        session = await cluster.create_session(keyspace=keyspace)
        await session.close()
        assert isinstance(result.msg, LogMessage)

    async def test_log_levels(self, host, keyspace):
        log = io.StringIO()
        handler = logging.StreamHandler(log)
        handler.setLevel(logging.DEBUG)
        handler.setFormatter(logging.Formatter("%(levelname)s"))
        logging.getLogger("acsylla").addHandler(handler)
        cluster = create_cluster([host], log_level="debug")
        session = await cluster.create_session(keyspace=keyspace)
        await session.close()
        assert "DEBUG" in log.getvalue().split("\n")

    async def test_set_log_levels(self, host, keyspace):
        cluster = create_cluster([host], log_level="disabled")
        cluster.set_log_level("disabled")
        cluster = create_cluster([host], log_level="critical")
        cluster.set_log_level("critical")
        cluster = create_cluster([host], log_level="error")
        cluster.set_log_level("error")
        cluster = create_cluster([host], log_level="warn")
        cluster.set_log_level("warn")
        cluster = create_cluster([host], log_level="warning")
        cluster.set_log_level("warning")
        cluster = create_cluster([host], log_level="info")
        cluster.set_log_level("info")
        cluster = create_cluster([host], log_level="debug")
        cluster.set_log_level("debug")
        cluster = create_cluster([host], log_level="trace")
        cluster.set_log_level("trace")
        with pytest.raises(ValueError):
            cluster = create_cluster([host], log_level="not_valid_level")
        with pytest.raises(ValueError):
            cluster.set_log_level("not_valid_level")
