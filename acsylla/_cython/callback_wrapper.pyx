cdef inline object cass_future_to_asyncio(CassFuture* cass_future, Cluster cluster):
    """Attach an asyncio.Future to a CassFuture.

    The returned future is resolved (via set_result(None)) from the event loop
    when the CassFuture completes.  The caller must `await` it.

    An extra reference to the future is taken here and released in
    Cluster._handle_events after set_result is called.  This keeps the future
    alive between the C callback push and the Python-side resolution.
    """
    cdef object future
    cdef CallbackContainer* container
    cdef CassError error

    future = cluster.loop.create_future()
    Py_INCREF(future)

    container = new CallbackContainer(
        <PosixToPython*>cluster.posix_to_python,
        <void*>future,
    )
    error = cass_future_set_callback(
        cass_future,
        <CassFutureCallback>posix_to_python_callback,
        <void*>container,
    )
    if error != CASS_OK:
        Py_DECREF(future)
        raise_if_error(error)

    return future
