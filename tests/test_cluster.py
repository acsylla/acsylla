from acsylla import Consistency
from acsylla import create_cluster

import pytest

pytestmark = pytest.mark.asyncio


class Testcreate_cluster:
    async def test_cluster_empty_host(self):
        with pytest.raises(ValueError):
            create_cluster([])

    async def test_cluster_invalid_protocol_version(self, host):
        with pytest.raises(ValueError):
            create_cluster([host], protocol_version=-1)

    async def test_cluster_override_timeouts(self, host):
        create_cluster([host], connect_timeout=1.0, request_timeout=1.0, resolve_timeout=1.0)

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
    async def test_cluster_override_consistency(self, host, consistency):
        create_cluster([host], consistency=consistency)

    async def test_cluster_authentication(self, host):
        with pytest.raises(ValueError):
            create_cluster([host], username="cassandra", password=None)
        with pytest.raises(ValueError):
            create_cluster([host], username=None, password="cassandra")

        create_cluster([host], username="cassandra", password="cassandra")
