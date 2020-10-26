from acsylla import create_cluster, create_statement, Consistency

import argparse
import asyncio
import logging
import random
import time
import uvloop

uvloop.install()

MAX_NUMBER_OF_KEYS = 65536

prepared_statement_write = None
prepared_statement_read = None

async def write(session, key, value, str_key, str_value):
    start = time.monotonic()
    statement = create_statement(
        "INSERT INTO test (id, value) values(" + str_key + "," + str_value + ")", consistency=Consistency.ONE
    )
    await session.execute(statement)
    return time.monotonic() - start


async def write_bind(session, key, value, *args):
    start = time.monotonic()
    statement = create_statement("INSERT INTO test (id, value) values(?, ?)", parameters=2)
    statement.bind(0, key)
    statement.bind(1, value)
    await session.execute(statement)
    return time.monotonic() - start

async def write_bind_list(session, key, value, *args):
    start = time.monotonic()
    statement = create_statement("INSERT INTO test (id, value) values(?, ?)", parameters=2)
    statement.bind_list([key, value])
    await session.execute(statement)
    return time.monotonic() - start


async def write_prepared_bind_list(session, key, value, *args):
    start = time.monotonic()
    statement = prepared_statement_write.bind()
    statement.bind_list([key, value])
    await session.execute(statement)
    return time.monotonic() - start


async def write_prepared_bind_dict(session, key, value, *args):
    start = time.monotonic()
    statement = prepared_statement_write.bind()
    statement.bind_dict({"id": key, "value": value})
    await session.execute(statement)
    return time.monotonic() - start


async def read(session, key, value, str_key, str_value):
    start = time.monotonic()
    statement = create_statement("SELECT id, value FROM test WHERE id =" + str_key)
    result = await session.execute(statement)
    if result.count() > 0:
        row = result.first()
        _ = row.column_by_name("value").int()

    return time.monotonic() - start

async def read_bind(session, key, value, *args):
    start = time.monotonic()
    statement = create_statement("SELECT id, value FROM test WHERE id = ?", parameters=1)
    statement.bind(0, key)
    result = await session.execute(statement)
    if result.count() > 0:
        row = result.first()
        _ = row.column_by_name("value").int()

    return time.monotonic() - start


async def read_bind_list(session, key, value, *args):
    start = time.monotonic()
    statement = create_statement("SELECT id, value FROM test WHERE id = ?", parameters=1)
    statement.bind_list([key])
    result = await session.execute(statement)
    if result.count() > 0:
        row = result.first()
        _ = row.column_by_name("value").int()

    return time.monotonic() - start


async def read_prepared_bind_list(session, key, value, *args):
    start = time.monotonic()
    statement = prepared_statement_read.bind()
    statement.bind_list([key])
    result = await session.execute(statement)
    if result.count() > 0:
        row = result.first()
        _ = row.column_by_name("value").int()

    return time.monotonic() - start


async def read_prepared_bind_dict(session, key, value, *args):
    start = time.monotonic()
    statement = prepared_statement_read.bind()
    statement.bind_dict({"id": key})
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
            key = random.randint(0, MAX_NUMBER_OF_KEYS)
            value = key
            str_key = str(key)
            str_value = str_key
            elapsed = await coro(session, key, value, str_key, str_value)
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
    global prepared_statement_write, prepared_statement_read
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
    
    prepared_statement_write = await session.create_prepared(
        "INSERT INTO test (id, value) values(:id, :value)"
    )
    prepared_statement_read = await session.create_prepared(
        "SELECT id, value FROM test WHERE id = :id"
    )

    await benchmark("write", write, session, args.concurrency, args.duration)
    await benchmark("write_bind", write_bind, session, args.concurrency, args.duration)
    await benchmark("write_bind_list", write_bind_list, session, args.concurrency, args.duration)
    await benchmark("write_prepared_bind_list", write_prepared_bind_list, session, args.concurrency, args.duration)
    await benchmark("write_prepared_bind_dict", write_prepared_bind_dict, session, args.concurrency, args.duration)
    await benchmark("read", read, session, args.concurrency, args.duration)
    await benchmark("read_bind", read_bind, session, args.concurrency, args.duration)
    await benchmark("read_bind_list", read_bind_list, session, args.concurrency, args.duration)
    await benchmark("read_prepared_bind_list", read_prepared_bind_list, session, args.concurrency, args.duration)
    await benchmark("read_prepared_bind_dict", read_prepared_bind_dict, session, args.concurrency, args.duration)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
