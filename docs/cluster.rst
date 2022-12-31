Cluster creation
----------------

Cluster creation is done exclusively through the asynchronous factory :meth:`acsylla.create_cluster`, this function returns a valid :class:`acsylla.Cluster` object that is used
later for executing statements..

By default :meth:`acsylla.create_cluster` only askes for one parameter, the list of contact points. Other parameters would be
configured to their default values when they are not provided.

For example

.. code-block:: python

    cluster = await acsylla.create_cluster(
        [
            '127.0.0.1',
        ]
    )

The previous example would return a :class:`acsylla.Cluster`. This object can be used for creating different :class:`acsylla.Session` objects as we will see later on.

When no other parameters are provided, the following keyword arguments are configured to the following default values:

- **protocol_versoin** Configured to use the **3 version**, override this parameter if you want to force the usage of another protocol version.
- **connect_timeout** Configured to timeout a connection after **5.0 seconds**, override this value if you want to have a different connection timeout. 
- **request_timeout** Configured to timeout a request after **2.0 seconds**, override this value if you want to have a different request timeout. 
- **resolve_timeout** Configured to timeout a DNS resolution after **1.0 seconds**, override this value if you want to have a different DNS resolution timeout. 

Like other parameters, timeouts can be overwritten also later on for a specific statement.

Example of a cluster creation that would configure the request timeout with a different value.

.. code-block:: python

    cluster = await acsylla.create_cluster(
        [
            '127.0.0.1',
        ],
        request_timeout=10.0
    )

Once cluster has been created we can use the :class:`acsylla.Cluster.create_session` method for creating a :class:`acsylla.Session` object, which is object that will be used for sending and
executing statements. By default no parameter is asked but we can provide the name of the keyspace, if it is provided the session created will use it for all of the statements executed using
the session object. If the keyspace is not provided all statement executions will fail, currently Acsylla does not yet provide support for configuring a keyspace at request time.

The following snippet shows how the session object is created for using the `acyslla` keyspace for all of the statements executed using the returned object:

.. code-block:: python

    cluster = await acsylla.create_cluster(
        [
            '127.0.0.1',
        ]
    )
    session = await cluster.create_session(keyspace='acsylla')
