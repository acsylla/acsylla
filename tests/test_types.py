from acsylla import types


class TestUUID:
    def test_uuid(self):
        uuid = types.uuid("this-should-be-an-uuid")
        assert uuid.uuid == "this-should-be-an-uuid"

    def test_equality(self):
        assert types.uuid("this-should-be-an-uuid") == types.uuid("this-should-be-an-uuid")
