API
===

Helpers
-------

.. autofunction:: acsylla.create_cluster
.. autofunction:: acsylla.create_statement
.. autofunction:: acsylla.create_batch_logged
.. autofunction:: acsylla.create_batch_unlogged
.. autofunction:: acsylla.create_batch_counter
.. autofunction:: acsylla.get_logger


Classes
-------

.. autoclass:: acsylla::Cluster
    :members:

.. autoclass:: acsylla::Session
    :members:

.. autoclass:: acsylla::Statement
    :members:

.. autoclass:: acsylla::PreparedStatement
    :members:

.. autoclass:: acsylla::Batch
    :members:

.. autoclass:: acsylla::Result
    :members:

.. autoclass:: acsylla::Row
    :members:

.. autoclass:: acsylla::Logger
    :members:

.. autoclass:: acsylla::Metadata
    :members:

Struct
------

.. autoclass:: acsylla::ColumnMeta
    :members:
    :undoc-members:

.. autoclass:: acsylla::Consistency
    :members:
    :undoc-members:

.. autoclass:: acsylla::DseGssapiAuthenticator
    :members:
    :undoc-members:

.. autoclass:: acsylla::DseGssapiAuthenticatorProxy
    :members:
    :undoc-members:

.. autoclass:: acsylla::DsePlaintextAuthenticator
    :members:
    :undoc-members:

.. autoclass:: acsylla::DsePlaintextAuthenticatorProxy
    :members:
    :undoc-members:

.. autoclass:: acsylla::FunctionMeta
    :members:
    :undoc-members:

.. autoclass:: acsylla::HostListenerEvent
    :members:
    :undoc-members:

.. autoclass:: acsylla::IndexMeta
    :members:
    :undoc-members:

.. autoclass:: acsylla::KeyspaceMeta
    :members:
    :undoc-members:

.. autoclass:: acsylla::LatencyAwareRoutingSettings
    :members:
    :undoc-members:

.. autoclass:: acsylla::LogMessage
    :members:
    :undoc-members:

.. autoclass:: acsylla::MaterializedViewMeta
    :members:
    :undoc-members:

.. autoclass:: acsylla::NestedTypeMeta
    :members:
    :undoc-members:

.. autoclass:: acsylla::ProtocolVersion
    :members:
    :undoc-members:

.. autoclass:: acsylla::SessionMetrics
    :members:
    :undoc-members:

.. autoclass:: acsylla::SpeculativeExecutionMetrics
    :members:
    :undoc-members:

.. autoclass:: acsylla::SpeculativeExecutionPolicy
    :members:
    :undoc-members:

.. autoclass:: acsylla::SSLVerifyFlags
    :members:
    :undoc-members:

.. autoclass:: acsylla::TableMeta
    :members:
    :undoc-members:

.. autoclass:: acsylla::UserTypeFieldMeta
    :members:
    :undoc-members:

.. autoclass:: acsylla::UserTypeMeta
    :members:
    :undoc-members:

Exceptions
----------

.. autoexception:: acsylla.errors.AggregateNotFound
.. autoexception:: acsylla.errors.CassErrorLibBadParams
.. autoexception:: acsylla.errors.CassErrorLibCallbackAlreadySet
.. autoexception:: acsylla.errors.CassErrorLibExecutionProfileInvalid
.. autoexception:: acsylla.errors.CassErrorLibHostResolution
.. autoexception:: acsylla.errors.CassErrorLibIndexOutOfBounds
.. autoexception:: acsylla.errors.CassErrorLibInternalError
.. autoexception:: acsylla.errors.CassErrorLibInvalidCustomType
.. autoexception:: acsylla.errors.CassErrorLibInvalidData
.. autoexception:: acsylla.errors.CassErrorLibInvalidErrorResultType
.. autoexception:: acsylla.errors.CassErrorLibInvalidFutureType
.. autoexception:: acsylla.errors.CassErrorLibInvalidItemCount
.. autoexception:: acsylla.errors.CassErrorLibInvalidState
.. autoexception:: acsylla.errors.CassErrorLibInvalidStatementType
.. autoexception:: acsylla.errors.CassErrorLibInvalidValueType
.. autoexception:: acsylla.errors.CassErrorLibMessageEncode
.. autoexception:: acsylla.errors.CassErrorLibNameDoesNotExist
.. autoexception:: acsylla.errors.CassErrorLibNoAvailableIoThread
.. autoexception:: acsylla.errors.CassErrorLibNoCustomPayload
.. autoexception:: acsylla.errors.CassErrorLibNoHostsAvailable
.. autoexception:: acsylla.errors.CassErrorLibNoPagingState
.. autoexception:: acsylla.errors.CassErrorLibNoStreams
.. autoexception:: acsylla.errors.CassErrorLibNotEnoughData
.. autoexception:: acsylla.errors.CassErrorLibNotImplemented
.. autoexception:: acsylla.errors.CassErrorLibNoTracingId
.. autoexception:: acsylla.errors.CassErrorLibNullValue
.. autoexception:: acsylla.errors.CassErrorLibParameterUnset
.. autoexception:: acsylla.errors.CassErrorLibRequestQueueFull
.. autoexception:: acsylla.errors.CassErrorLibRequestTimedOut
.. autoexception:: acsylla.errors.CassErrorLibUnableToClose
.. autoexception:: acsylla.errors.CassErrorLibUnableToConnect
.. autoexception:: acsylla.errors.CassErrorLibUnableToDetermineProtocol
.. autoexception:: acsylla.errors.CassErrorLibUnableToInit
.. autoexception:: acsylla.errors.CassErrorLibUnableToSetKeyspace
.. autoexception:: acsylla.errors.CassErrorLibUnexpectedResponse
.. autoexception:: acsylla.errors.CassErrorLibWriteError
.. autoexception:: acsylla.errors.CassErrorServerAlreadyExists
.. autoexception:: acsylla.errors.CassErrorServerBadCredentials
.. autoexception:: acsylla.errors.CassErrorServerConfigError
.. autoexception:: acsylla.errors.CassErrorServerFunctionFailure
.. autoexception:: acsylla.errors.CassErrorServerInvalidQuery
.. autoexception:: acsylla.errors.CassErrorServerIsBootstrapping
.. autoexception:: acsylla.errors.CassErrorServerOverloaded
.. autoexception:: acsylla.errors.CassErrorServerProtocolError
.. autoexception:: acsylla.errors.CassErrorServerReadFailure
.. autoexception:: acsylla.errors.CassErrorServerReadTimeout
.. autoexception:: acsylla.errors.CassErrorServerServerError
.. autoexception:: acsylla.errors.CassErrorServerSyntaxError
.. autoexception:: acsylla.errors.CassErrorServerTruncateError
.. autoexception:: acsylla.errors.CassErrorServerUnauthorized
.. autoexception:: acsylla.errors.CassErrorServerUnavailable
.. autoexception:: acsylla.errors.CassErrorServerUnprepared
.. autoexception:: acsylla.errors.CassErrorServerWriteFailure
.. autoexception:: acsylla.errors.CassErrorServerWriteTimeout
.. autoexception:: acsylla.errors.CassErrorSourceLib
.. autoexception:: acsylla.errors.CassErrorSourceServer
.. autoexception:: acsylla.errors.CassErrorSourceSsl
.. autoexception:: acsylla.errors.CassErrorSslClosed
.. autoexception:: acsylla.errors.CassErrorSslIdentityMismatch
.. autoexception:: acsylla.errors.CassErrorSslInvalidCert
.. autoexception:: acsylla.errors.CassErrorSslInvalidPeerCert
.. autoexception:: acsylla.errors.CassErrorSslInvalidPrivateKey
.. autoexception:: acsylla.errors.CassErrorSslNoPeerCert
.. autoexception:: acsylla.errors.CassErrorSslProtocolError
.. autoexception:: acsylla.errors.CassException
.. autoexception:: acsylla.errors.CassExceptionConnectionError
.. autoexception:: acsylla.errors.CassExceptionInvalidQuery
.. autoexception:: acsylla.errors.CassExceptionSyntaxError
.. autoexception:: acsylla.errors.ColumnNotFound
.. autoexception:: acsylla.errors.FunctionNotFound
.. autoexception:: acsylla.errors.IndexNotFound
.. autoexception:: acsylla.errors.KeyspaceNotFound
.. autoexception:: acsylla.errors.MaterializedViewNotFound
.. autoexception:: acsylla.errors.SchemaNotAvailable
.. autoexception:: acsylla.errors.TableNotFound
.. autoexception:: acsylla.errors.UserTypeNotFound
