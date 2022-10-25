import acsylla
import asyncio


async def pint_tracing_result(session, tracing_id):
    print("*" * 10, tracing_id, "*" * 10)
    statement = acsylla.create_statement("SELECT * FROM system_traces.sessions WHERE session_id = ?", 1)
    statement.bind(0, tracing_id)
    result = await session.execute(statement)
    for row in result:
        print("\n".join([f"\033[1m{k}:\033[0m {v}" for k, v in list(row)]))


async def tracing_example():
    cluster = acsylla.create_cluster(["localhost"])
    session = await cluster.create_session()
    # Statement tracing
    statement = acsylla.create_statement("SELECT release_version FROM system.local")
    statement.set_tracing(True)
    result = await session.execute(statement)
    await pint_tracing_result(session, result.tracing_id)
    # Batch tracing
    batch_statement1 = acsylla.create_statement("INSERT INTO acsylla.test (id, value) VALUES (1, 1)")
    batch_statement2 = acsylla.create_statement("INSERT INTO acsylla.test (id, value) VALUES (2, 2)")
    batch = acsylla.create_batch_logged()
    batch.add_statement(batch_statement1)
    batch.add_statement(batch_statement2)
    batch.set_tracing(True)
    result = await session.execute_batch(batch)
    await pint_tracing_result(session, result.tracing_id)


asyncio.run(tracing_example())
