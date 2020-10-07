from acsylla import create_cluster, create_statement, Consistency

import argparse
import asyncio
import logging
import random
import time
import uvloop

uvloop.install()

MAX_NUMBER_OF_KEYS = 65536


async def write(session, key, value):
    start = time.monotonic()
    statement = create_statement(
        "INSERT INTO test (id, value) values(" + key + "," + value + ")", consistency=Consistency.ONE
    )
    await session.execute(statement)
    return time.monotonic() - start


async def read(session, key, value):
    start = time.monotonic()
    statement = create_statement("SELECT id, value FROM test WHERE id =" + key)
    result = await session.execute(statement)
    if result.count() > 0:
        row = result.first()
        _ = row.column_by_name("value").int()

    return time.monotonic() - start


async def benchmark(desc: str, coro, session, concurrency: int, duration: int) -> None:
    print("Starting benchmark {}".format(desc))

    not_finish_benchmark = True

    async def run():
        nonlocal not_finish_benchmark
        times = []
        while not_finish_benchmark:
            key = str(random.randint(0, MAX_NUMBER_OF_KEYS))
            value = key
            elapsed = await coro(session, key, value)
            times.append(elapsed)
        return times

    tasks = [asyncio.ensure_future(run()) for _ in range(concurrency)]

    await asyncio.sleep(duration)

    not_finish_benchmark = False
    while not all([task.done() for task in tasks]):
        await asyncio.sleep(0)

    times = []
    for task in tasks:
        times += task.result()

    times.sort()

    total_ops = len(times)
    avg = sum(times) / total_ops

    p90 = times[int((90 * total_ops) / 100)]
    p99 = times[int((99 * total_ops) / 100)]

    print("Tests results:")
    print("\tOps/sec: {0}".format(int(total_ops / duration)))
    print("\tAvg: {0:.6f}".format(avg))
    print("\tP90: {0:.6f}".format(p90))
    print("\tP99: {0:.6f}".format(p99))


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--concurrency", help="Number of concurrency clients, by default 32", type=int, default=32,
    )
    parser.add_argument(
        "--duration", help="Test duration in seconds, by default 60", type=int, default=60,
    )
    args = parser.parse_args()

    cluster = create_cluster(["127.0.0.1"])
    session = await cluster.create_session(keyspace="acsylla")
    await benchmark("write", write, session, args.concurrency, args.duration)
    await benchmark("read", read, session, args.concurrency, args.duration)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
