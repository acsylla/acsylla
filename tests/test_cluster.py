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
