Welcome to acsylla's documentation!
===================================

.. _GitHub: https://github.com/acsylla/acsylla

A high performance Python Asyncio client library for Cassandra and ScyllaDB.

.. toctree::
   :maxdepth: 3
   :caption: Contents:

Installing
----------

- ``pip install acsylla``

Basic Usage
-----------

Following snippet shows what would be the basic stuff for creating a
:class:`acsylla.Session` through the :class:`acsylla.Cluster.create_session`
factory, and how the session returned can be used later for executing statements.

Take look to the following sections for understanding what are the different
parameters supported by the :meth:`acsylla.create_cluster` factory, how sessions
are built by using the
:class:`Cluster.create_session` and finally how how statements, prepared
statements and batch statements can be executed using a :class:`acsylla.Session` object.

.. code-block:: python

    import asyncio
    import acsylla
    async def main():
        cluster = acsylla.create_cluster([host])
        session = await cluster.create_session(keyspace="acsylla")
        statement = ascylla.create_statement("SELECT id, value FROM test WHERE id = 100")
        result = await session.execute(statement)
        row = result.first()
        value = row.column_value("value")
        await session.close()
    asyncio.run(main())

Contents
--------

.. toctree::
    :maxdepth: 3

    cluster
    session
    statements
    advanced_topics
    api

Indices and tables
------------------

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
