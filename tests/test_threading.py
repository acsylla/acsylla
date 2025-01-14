import threading

import acsylla
import asyncio
import queue
import pytest

pytestmark = pytest.mark.asyncio

async def select(session):
    async for row in session.query('select * from test'):
        dict(row)

async def async_task(name, delay):
    cluster = acsylla.create_cluster(['localhost'])
    cluster.set_log_level('debug')
    session = await cluster.create_session(keyspace='acsylla')
    for i in range(10):
        await select(session)
        await asyncio.sleep(delay)
    await session.close()

def run_asyncio_in_thread(delay, exc_queue):
    loop = asyncio.new_event_loop()
    try:
        loop.run_until_complete(async_task(f'test-{threading.current_thread()}', delay))
    except Exception as e:
        exc_queue.put(e)


class TestThreading:

    async def test_create_cluster_in_thread(self, keyspace):
        exc_queue = queue.Queue()
        thread = threading.Thread(target=run_asyncio_in_thread, args=(0, exc_queue))
        thread.start()
        thread2 = threading.Thread(target=run_asyncio_in_thread, args=(0, exc_queue))
        thread2.start()
        thread.join()
        thread2.join()
        while True:
            try:
                exc = exc_queue.get(block=False)
            except queue.Empty:
                break
            else:
                raise exc
