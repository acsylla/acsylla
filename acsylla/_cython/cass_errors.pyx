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


class CassErrorSourceLib(CassException):
    pass


class CassErrorSourceServer(CassException):
    pass


class CassErrorSourceSsl(CassException):
    pass


class CassErrorLibBadParams(CassErrorSourceLib):
    pass


class CassErrorLibNoStreams(CassErrorSourceLib):
    pass


class CassErrorLibUnableToInit(CassErrorSourceLib):
    pass


class CassErrorLibMessageEncode(CassErrorSourceLib):
    pass


class CassErrorLibHostResolution(CassErrorSourceLib):
    pass


class CassErrorLibUnexpectedResponse(CassErrorSourceLib):
    pass


class CassErrorLibRequestQueueFull(CassErrorSourceLib):
    pass


class CassErrorLibNoAvailableIoThread(CassErrorSourceLib):
    pass


class CassErrorLibWriteError(CassErrorSourceLib):
    pass


class CassErrorLibNoHostsAvailable(CassErrorSourceLib):
    pass


class CassErrorLibIndexOutOfBounds(CassErrorSourceLib):
    pass


class CassErrorLibInvalidItemCount(CassErrorSourceLib):
    pass


class CassErrorLibInvalidValueType(CassErrorSourceLib):
    pass


class CassErrorLibRequestTimedOut(CassErrorSourceLib):
    pass


class CassErrorLibUnableToSetKeyspace(CassErrorSourceLib):
    pass


class CassErrorLibCallbackAlreadySet(CassErrorSourceLib):
    pass


class CassErrorLibInvalidStatementType(CassErrorSourceLib):
    pass


class CassErrorLibNameDoesNotExist(CassErrorSourceLib):
    pass


class CassErrorLibUnableToDetermineProtocol(CassErrorSourceLib):
    pass


class CassErrorLibNullValue(CassErrorSourceLib):
    pass


class CassErrorLibNotImplemented(CassErrorSourceLib):
    pass


class CassErrorLibUnableToConnect(CassErrorSourceLib):
    pass


class CassErrorLibUnableToClose(CassErrorSourceLib):
    pass


class CassErrorLibNoPagingState(CassErrorSourceLib):
    pass


class CassErrorLibParameterUnset(CassErrorSourceLib):
    pass


class CassErrorLibInvalidErrorResultType(CassErrorSourceLib):
    pass


class CassErrorLibInvalidFutureType(CassErrorSourceLib):
    pass


class CassErrorLibInternalError(CassErrorSourceLib):
    pass


class CassErrorLibInvalidCustomType(CassErrorSourceLib):
    pass


class CassErrorLibInvalidData(CassErrorSourceLib):
    pass


class CassErrorLibNotEnoughData(CassErrorSourceLib):
    pass


class CassErrorLibInvalidState(CassErrorSourceLib):
    pass


class CassErrorLibNoCustomPayload(CassErrorSourceLib):
    pass


class CassErrorLibExecutionProfileInvalid(CassErrorSourceLib):
    pass


class CassErrorLibNoTracingId(CassErrorSourceLib):
    pass


class CassErrorServerServerError(CassErrorSourceServer):
    pass


class CassErrorServerProtocolError(CassErrorSourceServer):
    pass


class CassErrorServerBadCredentials(CassErrorSourceServer):
    pass


class CassErrorServerUnavailable(CassErrorSourceServer):
    pass


class CassErrorServerOverloaded(CassErrorSourceServer):
    pass


class CassErrorServerIsBootstrapping(CassErrorSourceServer):
    pass


class CassErrorServerTruncateError(CassErrorSourceServer):
    pass


class CassErrorServerWriteTimeout(CassErrorSourceServer):
    pass


class CassErrorServerReadTimeout(CassErrorSourceServer):
    pass


class CassErrorServerReadFailure(CassErrorSourceServer):
    pass


class CassErrorServerFunctionFailure(CassErrorSourceServer):
    pass


class CassErrorServerWriteFailure(CassErrorSourceServer):
    pass


class CassErrorServerSyntaxError(CassErrorSourceServer):
    pass


class CassErrorServerUnauthorized(CassErrorSourceServer):
    pass


class CassErrorServerInvalidQuery(CassErrorSourceServer):
    pass


class CassErrorServerConfigError(CassErrorSourceServer):
    pass


class CassErrorServerAlreadyExists(CassErrorSourceServer):
    pass


class CassErrorServerUnprepared(CassErrorSourceServer):
    pass


class CassErrorSslInvalidCert(CassErrorSourceSsl):
    pass


class CassErrorSslInvalidPrivateKey(CassErrorSourceSsl):
    pass


class CassErrorSslNoPeerCert(CassErrorSourceSsl):
    pass


class CassErrorSslInvalidPeerCert(CassErrorSourceSsl):
    pass


class CassErrorSslIdentityMismatch(CassErrorSourceSsl):
    pass


class CassErrorSslProtocolError(CassErrorSourceSsl):
    pass


class CassErrorSslClosed(CassErrorSourceSsl):
    pass
