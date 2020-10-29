cdef class TypeUUID:

    def __init__(self, str uuid):
        self.uuid = uuid

    def __eq__(self, TypeUUID other):
        return self.uuid == other.uuid
