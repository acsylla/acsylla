from acsylla import (
    Cluster,
    create_cluster,
    create_statement,
    PreparedStatement,
    Result,
    Row,
    Session,
    Statement,
    Value,
)

import pytest

pytestmark = pytest.mark.asyncio


async def test_types(host, keyspace, id_generation):
    id_ = next(id_generation)
    value = id_

    cluster: Cluster = create_cluster([host])
    session: Session = await cluster.create_session(keyspace=keyspace)
    statement: Statement = create_statement("INSERT INTO test (id, value) values(" + str(id_) + ", " + str(value) + ")")
    await session.execute(statement)

    # read the new inserted value
    prepared: PreparedStatement = await session.create_prepared("SELECT id, value FROM test WHERE id = ?")
    statement: Statement = prepared.bind()
    statement.bind_by_name("id", id_)
    result: Result = await session.execute(statement)

    _: int = result.count()
    _: int = result.column_count()

    row: Row = result.first()
    value: Value = row.column_by_name("id")
    _: int = value.int()
