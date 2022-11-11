class SchemaNotAvailable(CassException):
    pass

class KeyspaceNotFound(CassException):
    pass

class UserTypeNotFound(CassException):
    pass

class FunctionNotFound(CassException):
    pass

class AggregateNotFound(CassException):
    pass

class TableNotFound(CassException):
    pass

class ColumnNotFound(CassException):
    pass

class IndexNotFound(CassException):
    pass

class MaterializedViewNotFound(CassException):
    pass


cdef inline raise_if_error(CassError cass_error, bytes error_message = b''):
    # Note: consider to use `cass_future_get_error_result` instead to fill the
    #       exception with metadata.
    if cass_error == CASS_OK:
        return
    error_desc = cass_error_desc(cass_error)
    message = (f'{error_desc.decode()}: {error_message.decode()}')
    if cass_error == CASS_ERROR_LIB_BAD_PARAMS:
        raise CassErrorLibBadParams(message)
    elif cass_error == CASS_ERROR_LIB_NO_STREAMS:
        raise CassErrorLibNoStreams(message)
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_INIT:
        raise CassErrorLibUnableToInit(message)
    elif cass_error == CASS_ERROR_LIB_MESSAGE_ENCODE:
        raise CassErrorLibMessageEncode(message)
    elif cass_error == CASS_ERROR_LIB_HOST_RESOLUTION:
        raise CassErrorLibHostResolution(message)
    elif cass_error == CASS_ERROR_LIB_UNEXPECTED_RESPONSE:
        raise CassErrorLibUnexpectedResponse(message)
    elif cass_error == CASS_ERROR_LIB_REQUEST_QUEUE_FULL:
        raise CassErrorLibRequestQueueFull(message)
    elif cass_error == CASS_ERROR_LIB_NO_AVAILABLE_IO_THREAD:
        raise CassErrorLibNoAvailableIoThread(message)
    elif cass_error == CASS_ERROR_LIB_WRITE_ERROR:
        raise CassErrorLibWriteError(message)
    elif cass_error == CASS_ERROR_LIB_NO_HOSTS_AVAILABLE:
        raise CassErrorLibNoHostsAvailable(message)
    elif cass_error == CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS:
        raise CassErrorLibIndexOutOfBounds(message)
    elif cass_error == CASS_ERROR_LIB_INVALID_ITEM_COUNT:
        raise CassErrorLibInvalidItemCount(message)
    elif cass_error == CASS_ERROR_LIB_INVALID_VALUE_TYPE:
        raise CassErrorLibInvalidValueType(message)
    elif cass_error == CASS_ERROR_LIB_REQUEST_TIMED_OUT:
        raise CassErrorLibRequestTimedOut(message)
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_SET_KEYSPACE:
        raise CassErrorLibUnableToSetKeyspace(message)
    elif cass_error == CASS_ERROR_LIB_CALLBACK_ALREADY_SET:
        raise CassErrorLibCallbackAlreadySet(message)
    elif cass_error == CASS_ERROR_LIB_INVALID_STATEMENT_TYPE:
        raise CassErrorLibInvalidStatementType(message)
    elif cass_error == CASS_ERROR_LIB_NAME_DOES_NOT_EXIST:
        raise CassErrorLibNameDoesNotExist(message)
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_DETERMINE_PROTOCOL:
        raise CassErrorLibUnableToDetermineProtocol(message)
    elif cass_error == CASS_ERROR_LIB_NULL_VALUE:
        raise CassErrorLibNullValue(message)
    elif cass_error == CASS_ERROR_LIB_NOT_IMPLEMENTED:
        raise CassErrorLibNotImplemented(message)
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_CONNECT:
        raise CassErrorLibUnableToConnect(message)
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_CLOSE:
        raise CassErrorLibUnableToClose(message)
    elif cass_error == CASS_ERROR_LIB_NO_PAGING_STATE:
        raise CassErrorLibNoPagingState(message)
    elif cass_error == CASS_ERROR_LIB_PARAMETER_UNSET:
        raise CassErrorLibParameterUnset(message)
    elif cass_error == CASS_ERROR_LIB_INVALID_ERROR_RESULT_TYPE:
        raise CassErrorLibInvalidErrorResultType(message)
    elif cass_error == CASS_ERROR_LIB_INVALID_FUTURE_TYPE:
        raise CassErrorLibInvalidFutureType(message)
    elif cass_error == CASS_ERROR_LIB_INTERNAL_ERROR:
        raise CassErrorLibInternalError(message)
    elif cass_error == CASS_ERROR_LIB_INVALID_CUSTOM_TYPE:
        raise CassErrorLibInvalidCustomType(message)
    elif cass_error == CASS_ERROR_LIB_INVALID_DATA:
        raise CassErrorLibInvalidData(message)
    elif cass_error == CASS_ERROR_LIB_NOT_ENOUGH_DATA:
        raise CassErrorLibNotEnoughData(message)
    elif cass_error == CASS_ERROR_LIB_INVALID_STATE:
        raise CassErrorLibInvalidState(message)
    elif cass_error == CASS_ERROR_LIB_NO_CUSTOM_PAYLOAD:
        raise CassErrorLibNoCustomPayload(message)
    elif cass_error == CASS_ERROR_LIB_EXECUTION_PROFILE_INVALID:
        raise CassErrorLibExecutionProfileInvalid(message)
    elif cass_error == CASS_ERROR_LIB_NO_TRACING_ID:
        raise CassErrorLibNoTracingId(message)
    elif cass_error == CASS_ERROR_SERVER_SERVER_ERROR:
        raise CassErrorServerServerError(message)
    elif cass_error == CASS_ERROR_SERVER_PROTOCOL_ERROR:
        raise CassErrorServerProtocolError(message)
    elif cass_error == CASS_ERROR_SERVER_BAD_CREDENTIALS:
        raise CassErrorServerBadCredentials(message)
    elif cass_error == CASS_ERROR_SERVER_UNAVAILABLE:
        raise CassErrorServerUnavailable(message)
    elif cass_error == CASS_ERROR_SERVER_OVERLOADED:
        raise CassErrorServerOverloaded(message)
    elif cass_error == CASS_ERROR_SERVER_IS_BOOTSTRAPPING:
        raise CassErrorServerIsBootstrapping(message)
    elif cass_error == CASS_ERROR_SERVER_TRUNCATE_ERROR:
        raise CassErrorServerTruncateError(message)
    elif cass_error == CASS_ERROR_SERVER_WRITE_TIMEOUT:
        raise CassErrorServerWriteTimeout(message)
    elif cass_error == CASS_ERROR_SERVER_READ_TIMEOUT:
        raise CassErrorServerReadTimeout(message)
    elif cass_error == CASS_ERROR_SERVER_READ_FAILURE:
        raise CassErrorServerReadFailure(message)
    elif cass_error == CASS_ERROR_SERVER_FUNCTION_FAILURE:
        raise CassErrorServerFunctionFailure(message)
    elif cass_error == CASS_ERROR_SERVER_WRITE_FAILURE:
        raise CassErrorServerWriteFailure(message)
    elif cass_error == CASS_ERROR_SERVER_SYNTAX_ERROR:
        raise CassErrorServerSyntaxError(message)
    elif cass_error == CASS_ERROR_SERVER_UNAUTHORIZED:
        raise CassErrorServerUnauthorized(message)
    elif cass_error == CASS_ERROR_SERVER_INVALID_QUERY:
        raise CassErrorServerInvalidQuery(message)
    elif cass_error == CASS_ERROR_SERVER_CONFIG_ERROR:
        raise CassErrorServerConfigError(message)
    elif cass_error == CASS_ERROR_SERVER_ALREADY_EXISTS:
        raise CassErrorServerAlreadyExists(message)
    elif cass_error == CASS_ERROR_SERVER_UNPREPARED:
        raise CassErrorServerUnprepared(message)
    elif cass_error == CASS_ERROR_SSL_INVALID_CERT:
        raise CassErrorSslInvalidCert(message)
    elif cass_error == CASS_ERROR_SSL_INVALID_PRIVATE_KEY:
        raise CassErrorSslInvalidPrivateKey(message)
    elif cass_error == CASS_ERROR_SSL_NO_PEER_CERT:
        raise CassErrorSslNoPeerCert(message)
    elif cass_error == CASS_ERROR_SSL_INVALID_PEER_CERT:
        raise CassErrorSslInvalidPeerCert(message)
    elif cass_error == CASS_ERROR_SSL_IDENTITY_MISMATCH:
        raise CassErrorSslIdentityMismatch(message)
    elif cass_error == CASS_ERROR_SSL_PROTOCOL_ERROR:
        raise CassErrorSslProtocolError(message)
    elif cass_error == CASS_ERROR_SSL_CLOSED:
        raise CassErrorSslClosed(message)
    else:
        raise CassException(cass_error)
