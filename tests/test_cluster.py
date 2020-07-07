import pytest

from acsylla import Cluster


pytestmark = pytest.mark.asyncio


class TestCluster:
    async def test_cluster_empty_host(self):
        with pytest.raises(ValueError):
            Cluster([])

    async def test_cluster_invalid_protocol_version(self, host):
        with pytest.raises(ValueError):
            Cluster([host], protocol_version=-1)
