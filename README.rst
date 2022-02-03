acsylla
#######

WORK IN PROGRESS, use only for developing

acsylla a composition of async + cassandra + scylla words. (c) @pfreixes

Install
==========

There is an Alpha realease compabitble with Python 3.7, 3.8 and 3.9 for Linux and MacOS environments uploaded as a Pypi package. Use the following
command for installing it:

.. code-block:: bash

    pip install acsylla

For MacOS you would need to install the following libraries for make it work:

.. code-block:: bash

    brew install libuv openssl 

Usage
==========

The following snippet shows the minimal stuff that would be needed for creating a new ``Session``
object for the keyspace ``acsylla`` and then peform a query for reading a set of rows.

.. code-block:: python

    import asyncio
    import acsylla
    async def main():
        cluster = acsylla.create_cluster([host])
        session = await cluster.create_session(keyspace="acsylla")
        statement = acsylla.create_statement("SELECT id, value FROM test WHERE id=100")
        result = await session.execute(statement)
        row = result.first()
        value = row.column_value("value")
        await session.close()
    asyncio.run(main())


Acsylla comes with a minimal support for the following objects: ``Cluster``, ``Session``,
``Statement``, ``PreparedStatement``, ``Batch``, ``Result``, ``Row``.

Acsylla supports all native datatypes including `Collections` and `UDT`

Example for use prepared statement and paging.

.. code-block:: python

    import asyncio
    import acsylla

    async def main():
        cluster = acsylla.create_cluster(['localhost'])
        session = await cluster.create_session(keyspace="acsylla")
        prepared = await session.create_prepared("SELECT id, value FROM test")
        statement = prepared.bind(page_size=10, timeout=0.01)
        while True:
            result = await session.execute(statement)
            print(result.columns_names())
            # ['id', 'value']
            for row in result:
                print(dict(row))
                # {'id': 1, 'value': 'test'}
                print(list(row))
                # [('id', 1), ('value', 'test')]
                print(row.as_list())
                # [1, 'test']
                print(row.as_tuple())
                # (1, 'test')
            if result.has_more_pages():
                statement.set_page_size(100) # you can change statement settings on the fly
                statement.set_page_state(result.page_state())
            else:
                break

    asyncio.run(main())



.. code-block:: python

    import asyncio
    import acsylla

    class AsyncResultGenerator:
        def __init__(self, session, statement):
            self.session = session
            self.statement = statement

        async def __aiter__(self):
            result = await self.session.execute(self.statement)
            while True:
                if result.has_more_pages():
                    self.statement.set_page_state(result.page_state())
                    future_result = asyncio.create_task(
                        self.session.execute(self.statement))
                    await asyncio.sleep(0)
                else:
                    future_result = None
                for row in result:
                    yield dict(row)
                if future_result is not None:
                    result = await future_result
                else:
                    break
    def find(session, statement):
        return AsyncResultGenerator(session, statement)

    async def main():
        cluster = acsylla.create_cluster(['localhost'])
        session = await cluster.create_session(keyspace="acsylla")
        prepared = await session.create_prepared("SELECT id, value FROM test")

        statement = prepared.bind(page_size=10, timeout=0.01)

        async for res in find(session, statement):
            print(res)

    if __name__ == '__main__':
        asyncio.run(main())

Example for use `Shard-Awareness <https://github.com/scylladb/cpp-driver/tree/master/topics/scylla_specific>`__ connection to `Scylla` cluster.


.. code-block:: python

    import acsylla

    cluster = acsylla.create_cluster(['node1', 'node2', 'node3'],
        port=19042,                 # default: 9042
        protocol_version=4,         # default: 3
        core_connections_per_host=8,# default: 1
        local_port_range_min=49152, # default: 49152
        local_port_range_max=65535  # default: 65535
    )

SSL Connection example

.. code-block:: python

    import acsylla

    with open('./certs/client.cert.pem') as f:
        ssl_cert = f.read()
    with open('./certs/client.key.pem') as f:
        ssl_private_key = f.read()
    with open('./certs/trusted.cert.pem') as f:
        ssl_trusted_cert = f.read()

    cluster = create_cluster(['localhost'],
                             ssl_enabled=True,
                             ssl_cert=ssl_cert,
                             ssl_private_key=ssl_private_key,
                             ssl_trusted_cert=ssl_trusted_cert,
                             ssl_verify_flags=acsylla.SSLVerifyFlags.PEER_IDENTITY)



Developing
============

For developing you must clone the respository and first compile the CPP Cassandra driver, please
follow the `instructions <https://docs.datastax.com/en/developer/cpp-driver/2.6/topics/building/>`_
for installing any dependency that you would need for compiling the driver:

.. note::
    The driver depends on `libuv` and `openssl`. To install on Mac OS X, do `brew install libuv`
    and `brew install openssl` respectively. Additionally, you may need to export openssl lib
    locations: `export LDFLAGS="-L/usr/local/opt/openssl/lib"`
    and `export CPPFLAGS="-I/usr/local/opt/openssl/include"`.

.. code-block:: bash

    git clone git@github.com:pfreixes/acsylla.git
    make install-driver

Set up the environment and compile the package using the following commands:

.. code-block:: bash

    python -m venv venv
    source venv/bin/activate
    make compile
    make install-dev

And finally run the tests:

.. code-block:: bash

    docker-compose up -d
    make test
