import acsylla
import asyncio
import logging

logging.basicConfig(format="[%(levelname)1.1s %(asctime)s] (%(name)s) %(message)s")


class AsyncResultGenerator:
    def __init__(self, session, statement):
        self.session = session
        self.statement = statement

    async def __aiter__(self):
        result = await self.session.execute(self.statement)
        while True:
            if result.has_more_pages():
                self.statement.set_page_state(result.page_state())
                future_result = asyncio.create_task(self.session.execute(self.statement))
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
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session(keyspace="acsylla")
    prepared = await session.create_prepared("SELECT id, value FROM test")

    statement = prepared.bind(page_size=1000)

    async for row in find(session, statement):
        print(row)


if __name__ == "__main__":
    asyncio.run(main())
