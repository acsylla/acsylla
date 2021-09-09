Operations
----------
A :class:`emcache.Client` instance provides access to different Memcached operations, we can separate them into two categories:

- **Storage commands** Commands used for storing data to the  Memcached server
- **Fetch commands** Commands used for retrieving data from the Memcached server

Following snippet shows how a :meth:`emcache.Client.set` command can be performed by using a :class:`emcache.Client` instance:

.. code-block:: python

    client = await emcache.create_client(
        [emcache.MemcachedHostAddress('localhost', 11211)]
    )
    await client.set(b"key", b"value")
    await client.close()

By default the :class:`emcache.Client` instance provided by the :meth:`emcache.create_client` factory comes configured with a default timeout, so if it is not disabled
explicitly any operation might end up raising an :exc:`asyncio.TimeoutError`. As the following snippet
shows a good practice would be wrapping your operations for detecting this use cases for adding any specific logic.

.. code-block:: python

    try:
        await client.set(b"key", b"value")
    except asyncio.TimeoutError:
        logging.warning("Set operation timed out, retry?")

Storage commands
^^^^^^^^^^^^^^^^

Emcache has support for the following storage commands:

- :meth:`emcache.Client.set` Save a new key and value.
- :meth:`emcache.Client.add` Save a new key and value, if and only if the key does not exist.
- :meth:`emcache.Client.replace` Update value to an already existing key.
- :meth:`emcache.Client.append` Append a value to the existing value of an already existing key.
- :meth:`emcache.Client.prepend` Prepend a value to the existing value of an already existing key.
- :meth:`emcache.Client.cas` Update a key and its value using a ``cas`` token, if the current key already exists and has a different ``cas`` token the operation will fail.

Following snippet shows how the :meth:`emcache.Client.cas` operation can be used:

.. code-block:: python

    item = await client.gets(b"key")
    await client.cas(b"key", b"new value", item.cas)

Some of the storage commands would need to meet some conditions for finishing successfully, as it is the case of the `cas` command which requires to
provide a valid ``cas`` token or for the case of the :meth:`emcache.Clientadd` command which wouuld succeed if and only if the key would not exist. In all of these use
cases, when the command execution can not meet the requirements a :exc:`emcache.NotStoredStorageCommandError` is raised. The following
snippet shows how the :meth:`emcache.Client.cas` command could be wrapped for detecting this kind of situations:

.. code-block:: python

    try:
        await client.cas(
            b"key", b"new value", old_cas_value)
    except emcache.NotStoredStorageCommandError:
        logging.warning(
            "Cas token invalid, key couldn't be updated")

Most of the storage commands come with support for the following flags which they are exposed as keyword arguments for each of the operations:

- **flags** Store an ``int16`` value along with the value of the key, later on, this flags can be retrieved by the fetch commands
- **exptime** Expiration time of the key. By setting this value, with an absolute timestamp, the Memcached server will consider the key evicted
- **noreply** Do not wait for a confirmation from the Memcached server, fire and forget. You won't know if the operation finished successfully.

Following snippet shows how the :meth:`emcache.Client.set` command can be used for using the different flags explained above:.

.. code-block:: python

    await client.set(
        b"key", b"value",
        flags=4,
        # Expire in one hour
        exptime=int(time.time()) + 3600,
        # Do not ask for an explicit reply from Memcached
        noreply=True
    )

Fetch commands
^^^^^^^^^^^^^^

Fetch commands provide a way for retrieving data that has been saved before by using one of the storage commands that we have seen, :class:`emcache.Client` provides
the following methods for retrieving data from a Memcached server:

- :meth:`emcache.Client.get` Return value realated with a key.
- :meth:`emcache.Client.get` Return a value and the ``cas`` token related with a key.
- :meth:`emcache.Client.get_many` Return a set of values related to a set of keys.
- :meth:`emcache.Client.gets_many` Return a set of values and their ``cas`` tokens related to a set of keys.

Emcahe returns values as an instance of an :class:`emcache.Item` object which has the following attributes:

- :attr:`emcache.Item.value` Value of the key.
- :attr:`emcache.Item.cas` ``cas`` token of the key.
- :attr:`emcache.Item.flags` flags of the key.

Methods :meth:`emcache.Client.get` and :meth:`emcache.Client.get_many` would return :class:`emcache.Item` instances with only
the attr:`emcache.Item.value` set, and having the other ones left to ``None``, as can be seen in the following example:

.. code-block:: python

    item = await client.get(b"key")
    assert item.value is not None
    assert item.cas is None
    assert item.flags is None

For having access to the flags, the ``return_flags`` keyword would need to be set to ``True``. For retrieving the ``cas`` token the
:meth:`emcache.Client.gets` or :meth:`emcache.Client.gets_many` methods would need to be used, as can be seen in the following example:

.. code-block:: python

    item = await client.gets(b"key", return_flags=True)
    assert item.value is not None
    assert item.cas is not None
    assert item.flags is not None

The :meth:`emcache.Client.gets_many` and :meth:`emcache.Client.get_many` operations return a dictionary of the keys found, having as a value
the :class:`emcache.Item` of each key. For example:

.. code-block:: python

    await for key, item in client.get_many([b"key", b"key2"]).items():
        print(f"Key {key} found with value {item.value}")

Both methods might end up sending different commands to different nodes, depending on the outcome of the hashing algorithm. If this is the case,
the operation will give up completely in case of any error, raising an exception with the error and canceling the ongoing requests.

Other commands
^^^^^^^^^^^^^^

Emcache has also support for the following other commands:

- :meth:`emcache.Client.increment` Increases an already existing key by a value.
- :meth:`emcache.Client.decrement` Decreases an already existing key by a value.
- :meth:`emcache.Client.touch` Overrides the expiration time of an already existing key.
- :meth:`emcache.Client.delete` Deletes an existing key.
- :meth:`emcache.Client.flush_all` Flush all keys from an existing node, see notes below.

The :meth:`emcache.Client.flush_all` method targets a specific node, so the parameter expected is the :meth:`emcache.MemcachedHostAddress` which
identifies univocally a memcached host within the cluster. Also, a parameter called ``delay`` is supported for telling to the Memcached server that the
expiration of all of the keys should be done after a specific period of time. This option allows for example to delay the expiration of the keys
for each node in a different moment of time, which should help you on the way for mitigating the likely load that underlying resources might get because
of the increase of misses.

As an example, the following snippet shows how :meth:`emcache.Client.flush_all` can be used:

.. code-block:: python

    hosts = [
        emcache.MemcachedHostAddress('localhost', 11211),
        emcache.MemcachedHostAddress('localhost', 11212)
    ]

    for idx, host in enum(hosts):
        await client.flush_all(host, delay=10 + (10*idx))
