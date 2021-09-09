Advanced Topics
----------------

Hashing algorithm
^^^^^^^^^^^^^^^^^

The distribution alogithm is used for deciding which node of the cluster should deal with a specific key and it's based
on the `Rendezvous hashing <https://en.wikipedia.org/wiki/Rendezvous_hashing>`_ algorithm which is a generalized version
of the consistent hashing.

The Emcache implementation uses a constant and equal weight for all of the nodes and key hash uses an 8 bytes version of the
`murmur hash <https://en.wikipedia.org/wiki/MurmurHash>`_.

The main properties of the algorithm are:

- Idempotence, if the set of nodes does not vary, the same key would be handled by the same node again and again.
- In case of removing a node from the Cluster only the keys that were handled by the removed Node would be distributed across all of the other nodes.
- In case of an addition of a node to the Cluster, a percentage of the keys that were initially handled by one node will be handled by a different node.
  Theoretically, the number of keys affected should be equal to the percentage of the nodes added, for example by adding one node to a cluster of 10
  nodes, this should induce to have 10% of the keys routed to a different node.

One of the drawbacks of this algorithm is the performance when many nodes are used since the routing algorithm
needs to calculate the hash for a specific key for all of the nodes. This might have an impact when the size of the
cluster is about hundreds or thousands of nodes.

Connection Pool
^^^^^^^^^^^^^^^

The connection pool is the element that maintains the TCP connections opened to a specific node. Will be as many different instances of connections pools as many
nodes the cluster has.

By default the connection pool, if the default values are not overwritten, is initialized with the following characteristics:

- Create a maximum of 2 TCP connections. This can be changed by providing a different value of the ``max_connections`` keyword of the :meth:`emcache.create_client` factory.
- Purge unused connections, meaning that connections that once created are no longer used will be explicitly closed after 60 seconds. This can be changed
  by providing a different value of the ``purge_unused_connections_after`` keyword of the :meth:`emcache.create_client` factory or disabling it providing a `None` value.
- Give up by timeout after 5 seconds if a connection can't be created. This can be changed by providing a different value of the ``connection_timeout`` keyword
  of the :meth:`emcache.create_client` factory.

The maximum number of connections should be configured carefully, considering that connections are a limited resource that might have a noticeable impact on the
Memcached nodes. While having a limit of 32 connections might be a valid value for an environment with a few client instances, this would most likely become a to high value for an environment with a large number of instances.

Following table shows you the maximum throughput that has been achieved with a different number of connections with
a single client instance:

+------------+------------+
| Connections| Ops/sec    |
+============+============+
|          1 |      12127 |
+------------+------------+
|          2 |      19325 |
+------------+------------+
|          4 |      28721 |
+------------+------------+
|          8 |      38219 |
+------------+------------+
|         16 |      41355 |
+------------+------------+
|         32 |      49386 |
+------------+------------+
|         64 |      51410 |
+------------+------------+
|        128 |      52262 |
+------------+------------+

Any number beyond 32 TCP connections did not have a significant increase in the number of operations per second. By default, the connection pool comes configured with 2 maximum TCP connections,
which should provide in a modern CPU ~20K ops/sec.

Any provided number must be higher than 0, otherwise a :exc:`ValueError` will be raised. The connection pool will try to keep always at least one TCP connection opened even when there is no traffic.
Purging will not be applied for the last and unique TCP connection available.

Healthy and Unhealthy nodes
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Emcache follows the healthy status of each node by checking that at least there is one TCP connection established to them, if a Node can't be reached after a number of retries failed would be marked as
unhealthy. By default unhealthy hosts are still on use and for avoid sending traffic to them in further operations the ``purge_unhealthy_nodes`` of the :meth:`create_client` would need to be used, as can
seen in the following example:

.. code-block:: python

    client = await emcache.create_client(
        [
            emcache.MemcachedHostAddress('localhost', 11211),
            emcache.MemcachedHostAddress('localhost', 11212)
        ],
        purge_unhealthy_nodes=True
    )

When ``purge_unhealthy_nodes`` is used the nodes that have been marked as unhealthy will be removed from the pool of nodes used for the hashing algorithm, it would mean that they would not receive
 traffic until they would not report a healthy staus again. This behaviour would have at least the fowllowing direct implications:

- The traffic that was supposed to be send to the unhealthy nodes would suddently shifted to other nodes that are reporting a healthy status, this which might increase the total amount of traffic
  on the other nodes in a none negligible way. Therefore, the user would need to evaluate the cost of sending that traffic to other nodes is affordable or not.
- The hit/miss ratio might change. Since the keys that were suppose to be handled by the unhealthy nodes would be handled by other nodes, this might change in a none negligible way
  the hit/miss ratio. Therefore, the user would need to undestand the side effects of that situation.

When a node is considered unhealthy could become healthy again if and only if a new TCP connection can be stablished, the connection pool of a node will be on charge of keep trying to connect to
a specific node.

Cluster events
^^^^^^^^^^^^^^

Emcache allows you to listen for the more important events that happen at cluster level, the :meth:`create_client` method provides you a keyword argument called `cluster_events` which would need to be
set to a class instance of :class:`ClusterEvents`. If this instance is provided, Emcache will make specific hook calls for each of the events currently supported.

Following example shows how this parameter can be provided:

.. code-block:: python

    class ClusterEvents(emcache.ClusterEvents):

        async def on_node_healthy(self, cluster_managment, memcached_host_address):
            print(f"Node {memcached_host_address} reports a healthy status")

        async def on_node_unhealthy(self, cluster_managment, memcached_host_address):
            print(f"Node {memcached_host_address} reports an unhealthy status")

    client = await emcache.create_client(
        [
            emcache.MemcachedHostAddress('localhost', 11211),
            emcache.MemcachedHostAddress('localhost', 11212)
        ],
        cluster_events=ClusterEvents()
    )

Right now :class:`ClusterEvents` has only support for reporting events realated to changes of the node healthiness, the two hooks :meth:`on_node_healthy` and :meth:`on_node_unhealthy` would be
called - independntly of the `purge_unhealthy_nodes` configuration - when one of the nodes of the cluster change the healthy status. Besides of the argument for identifying univocally the node that is related
to a specifice event, as a first argument the :class:`ClusterManagment` instance will be provided which might be used for retrieving more information about the cluster and its nodes.

Events are dispatched in serie, meaning that behind the scenes Emcache will be calling one and only one hook at any moment, and order of the events will be guaranteed. The hook, due to the asynchronous nature might decide to run asynchronous operations, this might delay the delivery of pending messages. 
