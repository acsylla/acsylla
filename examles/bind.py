import acsylla
import asyncio


async def bind_by_index():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    statement = acsylla.create_statement("INSERT INTO test (id, value) VALUES (?, ?)", parameters=2)
    statement.bind(0, 1)
    statement.bind(1, 1)
    await session.execute(statement)


async def bind_list():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    statement = acsylla.create_statement("INSERT INTO test (id, value) VALUES (?, ?)", parameters=2)
    statement.bind_list([1, 1])
    await session.execute(statement)


asyncio.run(bind_by_index())
asyncio.run(bind_list())
