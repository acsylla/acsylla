import acsylla
import asyncio


async def bind_by_index():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("INSERT INTO test (id, value) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind(0, 1)
    statement.bind(1, 1)
    await session.execute(statement)


async def bind_by_name():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("INSERT INTO test (id, value) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind_by_name("id", 1)
    statement.bind_by_name("value", 1)
    await session.execute(statement)


async def bind_list():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("INSERT INTO test (id, value) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind_list([0, 1])
    await session.execute(statement)


async def bind_dict():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("INSERT INTO test (id, value) VALUES (?, ?)")
    statement = prepared.bind()
    statement.bind_dict({"id": 1, "value": 1})
    await session.execute(statement)


async def bind_named_parameters():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("INSERT INTO test (id, value) VALUES (:test_id, :test_value)")
    statement = prepared.bind()
    statement.bind_dict({"test_id": 1, "test_value": 1})
    await session.execute(statement)


asyncio.run(bind_by_index())
asyncio.run(bind_by_name())
asyncio.run(bind_list())
asyncio.run(bind_dict())
asyncio.run(bind_named_parameters())
