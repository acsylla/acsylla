from acsylla import Consistency
from acsylla import create_cluster
from acsylla import LatencyAwareRoutingSettings
from acsylla import SpeculativeExecutionPolicy

import functools
import pytest

pytestmark = pytest.mark.asyncio


class Testcreate_cluster:
    async def test_cluster_empty_host(self):
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

    async def test_cluster_whitelist_dc(self, host):
        create_cluster([host], whitelist_dc="dc2,dc3")

    async def test_cluster_blacklist_dc(self, host):
        create_cluster([host], blacklist_dc="dc2, dc3")

    async def test_cluster_whitelist_hosts(self, host):
        create_cluster([host], whitelist_hosts="127.0.0.1, 127.0.0.4")

    async def test_cluster_blacklist_hosts(self, host):
        create_cluster([host], blacklist_hosts="127.0.0.1, 127.0.0.4")

    async def test_cluster_create_execution_profile(self, host):
        latency_aware_routing = LatencyAwareRoutingSettings()
        speculative_execution_policy = SpeculativeExecutionPolicy(constant_delay_ms=100, max_speculative_executions=10)
        cluster = create_cluster([host])
        cluster.create_execution_profile(
            "test_profile",
            request_timeout=10,
            consistency=Consistency.LOCAL_ONE,
            serial_consistency=Consistency.LOCAL_ONE,
            load_balance_round_robin=True,
            load_balance_dc_aware="DC1",
            token_aware_routing=False,
            token_aware_routing_shuffle_replicas=False,
            latency_aware_routing=latency_aware_routing,
            whitelist_hosts="127.0.0.1",
            blacklist_hosts="127.0.0.4",
            whitelist_dc="dc1",
            blacklist_dc="dc2",
            retry_policy="default",
            retry_policy_logging=True,
            speculative_execution_policy=speculative_execution_policy,
        )

    async def test_cluster_host_listener_callback(self, host):
        events = []

        def host_listener_callback(event, host, events=None):
            events.append((event.name, host))

        callback = functools.partial(host_listener_callback, events=events)
        cluster = create_cluster([host], host_listener_callback=callback)
        await cluster.create_session()
        assert events[0] in [("ADD", "127.0.0.1"), ("UP", "127.0.0.1")]

    async def test_cluster_set_host_listener_callback(self, host):
        events = []

        def host_listener_callback(event, host, events=None):
            events.append((event.name, host))

        callback = functools.partial(host_listener_callback, events=events)
        cluster = create_cluster([host], host_listener_callback=callback)
        cluster.set_host_listener_callback(None)
        await cluster.create_session()
        assert events == []
