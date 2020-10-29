class ColumnNotFound(CassException):
    pass


cdef inline raise_if_error(CassError cass_error):
    # Note: consider to use `cass_future_get_error_result` instead to fill the
    #       exception with metadata.
    if cass_error == CASS_OK:
        return

    if cass_error == CASS_ERROR_LIB_BAD_PARAMS:
        raise CassErrorLibBadParams()
    elif cass_error == CASS_ERROR_LIB_NO_STREAMS:
        raise CassErrorLibNoStreams()
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_INIT:
        raise CassErrorLibUnableToInit()
    elif cass_error == CASS_ERROR_LIB_MESSAGE_ENCODE:
        raise CassErrorLibMessageEncode()
    elif cass_error == CASS_ERROR_LIB_HOST_RESOLUTION:
        raise CassErrorLibHostResolution()
    elif cass_error == CASS_ERROR_LIB_UNEXPECTED_RESPONSE:
        raise CassErrorLibUnexpectedResponse()
    elif cass_error == CASS_ERROR_LIB_REQUEST_QUEUE_FULL:
        raise CassErrorLibRequestQueueFull()
    elif cass_error == CASS_ERROR_LIB_NO_AVAILABLE_IO_THREAD:
        raise CassErrorLibNoAvailableIoThread()
    elif cass_error == CASS_ERROR_LIB_WRITE_ERROR:
        raise CassErrorLibWriteError()
    elif cass_error == CASS_ERROR_LIB_NO_HOSTS_AVAILABLE:
        raise CassErrorLibNoHostsAvailable()
    elif cass_error == CASS_ERROR_LIB_INDEX_OUT_OF_BOUNDS:
        raise CassErrorLibIndexOutOfBounds()
    elif cass_error == CASS_ERROR_LIB_INVALID_ITEM_COUNT:
        raise CassErrorLibInvalidItemCount()
    elif cass_error == CASS_ERROR_LIB_INVALID_VALUE_TYPE:
        raise CassErrorLibInvalidValueType()
    elif cass_error == CASS_ERROR_LIB_REQUEST_TIMED_OUT:
        raise CassErrorLibRequestTimedOut()
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_SET_KEYSPACE:
        raise CassErrorLibUnableToSetKeyspace()
    elif cass_error == CASS_ERROR_LIB_CALLBACK_ALREADY_SET:
        raise CassErrorLibCallbackAlreadySet()
    elif cass_error == CASS_ERROR_LIB_INVALID_STATEMENT_TYPE:
        raise CassErrorLibInvalidStatementType()
    elif cass_error == CASS_ERROR_LIB_NAME_DOES_NOT_EXIST:
        raise CassErrorLibNameDoesNotExist()
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_DETERMINE_PROTOCOL:
        raise CassErrorLibUnableToDetermineProtocol()
    elif cass_error == CASS_ERROR_LIB_NULL_VALUE:
        raise CassErrorLibNullValue()
    elif cass_error == CASS_ERROR_LIB_NOT_IMPLEMENTED:
        raise CassErrorLibNotImplemented()
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_CONNECT:
        raise CassErrorLibUnableToConnect()
    elif cass_error == CASS_ERROR_LIB_UNABLE_TO_CLOSE:
        raise CassErrorLibUnableToClose()
    elif cass_error == CASS_ERROR_LIB_NO_PAGING_STATE:
        raise CassErrorLibNoPagingState()
    elif cass_error == CASS_ERROR_LIB_PARAMETER_UNSET:
        raise CassErrorLibParameterUnset()
    elif cass_error == CASS_ERROR_LIB_INVALID_ERROR_RESULT_TYPE:
        raise CassErrorLibInvalidErrorResultType()
    elif cass_error == CASS_ERROR_LIB_INVALID_FUTURE_TYPE:
        raise CassErrorLibInvalidFutureType()
    elif cass_error == CASS_ERROR_LIB_INTERNAL_ERROR:
        raise CassErrorLibInternalError()
    elif cass_error == CASS_ERROR_LIB_INVALID_CUSTOM_TYPE:
        raise CassErrorLibInvalidCustomType()
    elif cass_error == CASS_ERROR_LIB_INVALID_DATA:
        raise CassErrorLibInvalidData()
    elif cass_error == CASS_ERROR_LIB_NOT_ENOUGH_DATA:
        raise CassErrorLibNotEnoughData()
    elif cass_error == CASS_ERROR_LIB_INVALID_STATE:
        raise CassErrorLibInvalidState()
    elif cass_error == CASS_ERROR_LIB_NO_CUSTOM_PAYLOAD:
        raise CassErrorLibNoCustomPayload()
    elif cass_error == CASS_ERROR_LIB_EXECUTION_PROFILE_INVALID:
        raise CassErrorLibExecutionProfileInvalid()
    elif cass_error == CASS_ERROR_LIB_NO_TRACING_ID:
        raise CassErrorLibNoTracingId()
    elif cass_error == CASS_ERROR_SERVER_SERVER_ERROR:
        raise CassErrorServerServerError()
    elif cass_error == CASS_ERROR_SERVER_PROTOCOL_ERROR:
        raise CassErrorServerProtocolError()
    elif cass_error == CASS_ERROR_SERVER_BAD_CREDENTIALS:
        raise CassErrorServerBadCredentials()
    elif cass_error == CASS_ERROR_SERVER_UNAVAILABLE:
        raise CassErrorServerUnavailable()
    elif cass_error == CASS_ERROR_SERVER_OVERLOADED:
        raise CassErrorServerOverloaded()
    elif cass_error == CASS_ERROR_SERVER_IS_BOOTSTRAPPING:
        raise CassErrorServerIsBootstrapping()
    elif cass_error == CASS_ERROR_SERVER_TRUNCATE_ERROR:
        raise CassErrorServerTruncateError()
    elif cass_error == CASS_ERROR_SERVER_WRITE_TIMEOUT:
        raise CassErrorServerWriteTimeout()
    elif cass_error == CASS_ERROR_SERVER_READ_TIMEOUT:
        raise CassErrorServerReadTimeout()
    elif cass_error == CASS_ERROR_SERVER_READ_FAILURE:
        raise CassErrorServerReadFailure()
    elif cass_error == CASS_ERROR_SERVER_FUNCTION_FAILURE:
        raise CassErrorServerFunctionFailure()
    elif cass_error == CASS_ERROR_SERVER_WRITE_FAILURE:
        raise CassErrorServerWriteFailure()
    elif cass_error == CASS_ERROR_SERVER_SYNTAX_ERROR:
        raise CassErrorServerSyntaxError()
    elif cass_error == CASS_ERROR_SERVER_UNAUTHORIZED:
        raise CassErrorServerUnauthorized()
    elif cass_error == CASS_ERROR_SERVER_INVALID_QUERY:
        raise CassErrorServerInvalidQuery()
    elif cass_error == CASS_ERROR_SERVER_CONFIG_ERROR:
        raise CassErrorServerConfigError()
    elif cass_error == CASS_ERROR_SERVER_ALREADY_EXISTS:
        raise CassErrorServerAlreadyExists()
    elif cass_error == CASS_ERROR_SERVER_UNPREPARED:
        raise CassErrorServerUnprepared()
    elif cass_error == CASS_ERROR_SSL_INVALID_CERT:
        raise CassErrorSslInvalidCert()
    elif cass_error == CASS_ERROR_SSL_INVALID_PRIVATE_KEY:
        raise CassErrorSslInvalidPrivateKey()
    elif cass_error == CASS_ERROR_SSL_NO_PEER_CERT:
        raise CassErrorSslNoPeerCert()
    elif cass_error == CASS_ERROR_SSL_INVALID_PEER_CERT:
        raise CassErrorSslInvalidPeerCert()
    elif cass_error == CASS_ERROR_SSL_IDENTITY_MISMATCH:
        raise CassErrorSslIdentityMismatch()
    elif cass_error == CASS_ERROR_SSL_PROTOCOL_ERROR:
        raise CassErrorSslProtocolError()
    elif cass_error == CASS_ERROR_SSL_CLOSED:
        raise CassErrorSslClosed()
    else:
        raise CassException(cass_error)
