Session creation
---------------

Session creation is done exclusively through the asynchronous factory :meth:`emcache.create_client`, this function returns a valid :class:`emcache.Client` object that is used
later for making all of the operations, like :meth:`emcache.Client.get` or :meth:`emcache.Client.set`.

By default :meth:`emcache.create_client` only askes for one parameter, the list of the Memcached host addresses, hosts, and ports. Other parameters would be
configured to their default values when they are not provided.

For example

.. code-block:: python

    client = await emcache.create_client(
        [
            emcache.MemcachedHostAddress('localhost', 11211),
            emcache.MemcachedHostAddress('localhost', 11212)
        ]
    )

The previous example would return a :class:`emcache.Client` object instance that will perform the operations to two different Nodes, depending on the outcome of the hashing algorithm.
Take a look to the advanced topics section and specifically to the Hashing section for understanding how operations are being routed to the different nodes.

When no other parameters are provided, the following keyword arguments are configured to the following default values:

- **timeout** Enabled and configured to **1.0 seconds**, meaning that any operation that might take more than 1 second would be considered timed out and an :exc:`asyncio.TimeoutError` would be triggered
  For disabling timeouts at operation level a `None` value can be provided.
- **max_connections** Configured to 2, maximum number of TCP connections that would be opened per node. Consider configure that number according to the maximum number of concurrent
  clients that you might have and the impact that these connections might have for the Memcached server. Take look to the advanced topics section, and specifically to the 
  Connection pool section.
- **purge_unused_connections_after** By default enabled and conigured to **60.0 secconds**. If you do not want to purge actively - close - connections that haven't been used for a while give a `None` value.
- **connection_timeout** By default configured to **5 seconds**, meaning that any attempt of creating a new connection that might take more than 5 seconds would be considered timed out.
  For disabling that time out give a `None` value.
- **cluster_events** By default configured to `None`. Take a look to the advanced topics section, and specifically to the cluster events section.
- **purge_unhealthy_nodes** By default configured to False, if it was configured to True traffic wouldn't be send to nodes that are reporting an unhealthy status. Take a look to the advanced topics section, and specifically to the healthy and unhealhty nodes section.

Example of a client creation that would not purge unused connections

.. code-block:: python

    client = await emcache.create_client(
        [
            emcache.MemcachedHostAddress('localhost', 11211),
            emcache.MemcachedHostAddress('localhost', 11212)
        ],
        purge_unused_connections_after=None
    )


Some underlying resources are started as background tasks when the client is instantiated, these resources would need to be closed gracefully using the :meth:`emcache.Client.close` method. This method will trigger all of the job necessary for releasing these resources. The following snippet shows how this method can be used:

.. code-block:: python

    client = await emcache.create_client(
        [
            emcache.MemcachedHostAddress('localhost', 11211),
            emcache.MemcachedHostAddress('localhost', 11212)
        ]
    )

    await client.close()
