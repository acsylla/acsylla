import acsylla
import asyncio


async def main():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    await asyncio.sleep(3)
    metadata = session.get_metadata()
    for keyspace in metadata.get_keyspaces():
        print("keyspace==>", keyspace)
        keyspace_metadata = metadata.get_keyspace_meta(keyspace)
        print("\n\n".join(keyspace_metadata.as_cql_query(formatted=True)))
    await session.close()


asyncio.run(main())
