class CassException(Exception):
    """ Generic Cassandra Error. """


class CassExceptionConnectionError(CassException):
    """ Raised when server can't be reached. """


class CassExceptionSyntaxError(CassException):
    """ Raised when a statment presented a syntax error. """


class CassExceptionInvalidQuery(CassException):
    """ Raised when a statment presented an invalid query,
    for example using an invalid type.
    """

