import acsylla
import asyncio


async def main():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session()
    await session.query(
        """
        CREATE KEYSPACE IF NOT EXISTS acsylla WITH REPLICATION = { 
            'class': 'SimpleStrategy', 'replication_factor': 1
        }
        """
    )
    await session.use_keyspace("acsylla")
    await session.query(
        """
        CREATE TABLE IF NOT EXISTS test (
            id tinyint PRIMARY KEY,
            value int
        );
        """
    )
    insert = await session.prepared_query("INSERT INTO test (id, value) VALUES (?, ?)")
    await asyncio.gather(*[insert([i, i]) for i in range(100)])
    select = await session.prepared_query("SELECT * FROM test WHERE id IN :id")
    async for row in select([(1, 4, 7, 90)]):
        print(row.as_tuple())

    non_prepared = session.query("SELECT * FROM test WHERE id=:id")
    async for row in non_prepared([7], value_types=[acsylla.ValueType.TINY_INT]):
        print(dict(row))


asyncio.run(main())
