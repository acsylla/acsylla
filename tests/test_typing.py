from acsylla import Cluster
from acsylla import create_cluster
from acsylla import create_statement
from acsylla import PreparedStatement
from acsylla import Result
from acsylla import Row
from acsylla import Session
from acsylla import Statement


class TestTyping:
    async def test_types(self, host, keyspace, id_generation):
        id_ = next(id_generation)
        value = id_

        cluster: Cluster = create_cluster([host])
        session: Session = await cluster.create_session(keyspace=keyspace)
        statement: Statement = create_statement(
            "INSERT INTO test (id, value) values(" + str(id_) + ", " + str(value) + ")"
        )
        await session.execute(statement)

        # read the new inserted value
        prepared: PreparedStatement = await session.create_prepared("SELECT id, value FROM test WHERE id = ?")
        statement: Statement = prepared.bind()
        statement.bind_by_name("id", id_)
        result: Result = await session.execute(statement)

        _: int = result.count()
        _: int = result.column_count()

        row: Row = result.first()
        _: int = row.column_value("id")
