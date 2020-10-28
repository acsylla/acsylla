from acsylla import types


class TestUUID:
    def test_uuid(self):
        uuid = types.uuid("this-should-be-an-uuid")
        assert uuid.uuid == "this-should-be-an-uuid"
