import argparse
import asyncio
import logging
import random
import time
from typing import List

import uvloop

from acsylla import Cluster

uvloop.install()

MAX_NUMBER_OF_KEYS = 65536

async def benchmark(desc: str, session, concurrency: int, duration: int) -> None:
    print("Starting benchmark {}".format(desc))

    not_finish_benchmark = True

    async def run():
        nonlocal not_finish_benchmark
        times = []
        while not_finish_benchmark:
            key = str(random.randint(0, MAX_NUMBER_OF_KEYS)).encode()
            value = key
            statement = b"INSERT INTO test (id, value) values(" + key + b"," + value + b")"
            start = time.monotonic()
            await session.execute(statement)
            elapsed = time.monotonic() - start
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

    cluster = Cluster(["127.0.0.1"])
    session = await cluster.create_session(keyspace="acsylla")
    await benchmark("write", session, args.concurrency, args.duration)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
