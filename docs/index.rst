.. acsylla documentation master file, created by
   sphinx-quickstart on Thu May 21 22:20:26 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to acsylla's documentation!
===================================

A high performance asynchronous Python client for Cassandra and Scylla.

.. toctree::
   :maxdepth: 2
   :caption: Contents:

Installing
----------

- ``pip install acsylla``

Basic Usage
-----------

Following snippet shows what would be the basic stuff for creating a :class:`acsylla.Session` through the :class:`acsylla.Cluster.create_session` factory, and how the session returned can be used later for executing statements.

Take look to the following sections for understanding what are the different parameters supported by the :meth:`acsylla.create_cluster` factory, how sessions are built by using the
:class:`Cluster.create_session` and finally how how statements, prepared statements and batch statements can be executed using a :class:`acsylla.Session` object.

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

  cluster
  session 
  statements 
  advanced_topics
