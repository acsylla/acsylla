class CassException(Exception):
    """ Generic Cassandra Error. """
    pass


class CassExceptionSyntaxError(CassException):
    """ Raised when a statment presented a syntax error. """

    def __init__(self, statment):
        self.statment = statment
        super().__init__(self)
