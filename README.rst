acsylla
#######

WORK IN PROGRESS, use only for developing

The following snippet shows the minimal stuff that would be needed for creating a new ``Session``
object for the keyspace ``acsylla`` and then peform a query for reading a set of rows.

.. code-block:: python

    import asyncio
    import acsylla
    async def main():
        cluster = acsylla.create_cluster([host])
        session = await cluster.create_session(keyspace="acsylla")
        statement = ascylla.create_statement("SELECT id, value FROM test WHERE id = 100")
        result = await session.execute(statement)
        row = result.first()
        value = row.column_by_name("value")
        await session.close()
    asyncio.run(main())


Acsylla comes with a minimal support for the following objects: ``Cluster``, ``Session``,
``Statement``, ``PreparedStatement``, ``Batch``, ``Result``, ``Row`` and ``Value``.


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
