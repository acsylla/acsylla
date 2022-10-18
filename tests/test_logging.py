from acsylla import create_cluster
from acsylla import LogMessage

import functools
import io
import logging
import pytest

pytestmark = pytest.mark.asyncio


class Testcreate_cluster:
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
