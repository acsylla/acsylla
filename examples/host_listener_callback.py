import acsylla
import asyncio


def host_listener_callback(event: acsylla.HostListenerEvent, host: str):
    if event == acsylla.HostListenerEvent.UP:
        print("Host", host, "is UP")
    else:
        print(event.name, host)


async def main():
    cluster = acsylla.create_cluster(["localhost"], host_listener_callback=host_listener_callback)
    session = await cluster.create_session(keyspace="acsylla")
    await session.close()


asyncio.run(main())
