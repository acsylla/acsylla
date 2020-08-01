class CassException(Exception):
    """ Generic Cassandra Error. """
    pass


class CassExceptionConnectionError(CassException):
    """ Raised when server can't be reached. """


class CassExceptionSyntaxError(CassException):
    """ Raised when a statment presented a syntax error. """

    def __init__(self, statment):
        self.statment = statment
        super().__init__(self)


class CassExceptionInvalidQuery(CassException):
    """ Raised when a statment presented an invalid query,
    for example using an invalid type.
    """

    def __init__(self, statment):
        self.statment = statment
        super().__init__(self)
