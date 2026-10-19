Changelog
=========

1.2.0
======
- Route requests to the replicas and shards of their tablets, up to 38% faster reads on ScyllaDB with tablets (patch for cpp-driver `vendor/tablets-routing.patch`)
- Fix routing of statements without a routing key, they always went to the same shard, 2x faster simple statements (patch for cpp-driver `vendor/routing-key-token.patch`)
- Write a request right away when there is little to coalesce it with, up to 10x faster at low concurrency without changing `coalesce_delay_us` (patch for cpp-driver `vendor/coalesce-wakeup.patch`)
- Use jemalloc 5.3.0 for the driver memory allocations, up to 23% more throughput when the event loop is saturated. It is downloaded and linked statically when building from source, allocations of Python are not affected (patch for cpp-driver `vendor/jemalloc-allocator.patch`)
- Bind statement values without a Python call per value, up to 37% faster binding
- Bind text, inet, uuid, date, time, collections, tuples and UDT values twice as fast, up to 12% faster inserts of rows with them
- Open the connections to all shards of a ScyllaDB node right away once it answers instead of after the 2 second reconnect delay (patch for cpp-driver `vendor/connect-shards-now.patch`)
- Fix a crash when a ScyllaDB node that was down when the session started comes back (patch for cpp-driver `vendor/pool-learns-shards.patch`)
- Keep using a ScyllaDB node that comes back with another IP address instead of ignoring it, and drop its old address (patch for cpp-driver `vendor/node-address-change.patch`)
- Support TLS 1.3, the driver was limited to TLS 1.2 and could not connect to a server that accepts only TLS 1.3 (patch for cpp-driver `vendor/tls13.patch`, from CASSCPP-16 of apache/cassandra-cpp-driver)
- Trust all the certificates of `ssl_trusted_cert`, not only the first one of a bundle (patch for cpp-driver `vendor/trusted-cert-bundle.patch`, from apache/cassandra-cpp-driver#522)
- Use `inspect.iscoroutinefunction`, `asyncio.iscoroutinefunction` is deprecated since Python 3.14

1.1.2
======
- Fix possible event loop deadlock under high load
- Wake up the event loop only when the queue was empty
- Add `acsylla.metadata` with CQL keywords as in python-driver [#107](https://github.com/acsylla/acsylla/issues/107)

1.1.1
======
- Add support for Python 3.15 and 3.15t
- Update LIBUV_VERSION to 1.53.0
- Fix `as_cql_query()` of metadata for names that are reserved CQL keywords or case-sensitive, all names are quoted now
- Fix duplicated user type in metadata when the type name needs quotes (patch for cpp-driver `vendor/unquote-udt-name.patch`)
- Fix order of user types in `KeyspaceMeta.as_cql_query()`, a type is created after the types it uses
- Fix build with OpenSSL 4.0 (patch for cpp-driver `vendor/openssl4-const.patch`)

1.1.0
======
- Improve performance
- Update LIBUV_VERSION to 1.52.1
- Add build for musllinux
- Remove Python 3.8 from CI

1.0.2
======
- Fix gh release actions 
- Include v1.0.1 Fix milliseconds in timestamps [#97](https://github.com/acsylla/acsylla/pull/97)
- Fix Using acsylla.get_logger() raises an AttributeError  [#97](https://github.com/acsylla/acsylla/pull/98)
- Update LIBUV_VERSION to 1.51.0
- Add support for Python 3.14

1.0.1
======
- Fix milliseconds in timestamps [#97](https://github.com/acsylla/acsylla/pull/97)

1.0.0
========
- !!! (maybe breaking change) add tzinfo=UTC for returned datetime field
- Add ability to create cluster in different threads with different event loop 
- Add alias `Session.use_keyspace` for `Session.set_keyspace`
- Add alias `Session.prepared_query` for `Session.create_prepared`
- Add method `Session.query` for creating `Statement`
- Make `PreparedStatement` and `Statement` callable and async iterable (for example see Basic usage in README.md)
- Allow `Row` to be accessed by attributes
- Fix `host_listener_callback`
- Add `value_types` for non-prepared `Statement` and `ValueType` to support binding non-native Python data types (e.g., `tiny_int`, etc.)
  - Note: Binding collections (map, set, list, tuple) and UDT types is not yet implemented for non-prepared statements

0.2.1
========
- Add support python3.13 
- Updating libuv version to 1.49.2

0.2.0
========
- Add support python3.12 
- Update code to support latest Cython 3.0.10
- Remove python3.7 from CI 

0.1.8b1
========
- Add host listener callback 
- Refactoring `Logger`
- Update docs

0.1.8b0
========
- Add metadata support
- Add logging
- Add Blacklist, whitelist DC, and blacklist, whitelist hosts load balancing policies
- Add execution profiles
- Add Speculative retry support
- Add Retry policy configuration support
- Add all configuration options for `Cluster`, `Statement` and `Batch`
- Update cpp-driver to latest version
- Static link OpenSSL and libuv for MacOS wheel
- Support for Pyhton 3.11

0.1.7a0
========
- Fixed issue with `execute_batch`
- Fixed issue with cancelled tasks which impacted comunication between Python Asyncio and CPP Driver
- Add support for SSL
- Support for Pyhton 3.10

0.1.6a0
========
- Add plain text authentication create_cluster(…, username=“test”, password=“test”)
- Add public methods for Statement:
  - set_timeout
  - set_consistency
  - set_serial_consistency
  - set_page_size
  - set_page_state
- Add cass_cluster_set_local_port_range  create_cluster(…, local_port_range_min=49152, local_port_range_max=65535)
- Add convert value to str before bind Decimal type
- Add support for iterate over Result and Row objects
- Add new methods for fetch values from Row object: 
  - dict(Row) same as Row.as_dict() returns dict where key is column name 
  - list(Row) same as Row.as_named_tuple() return list of tuple with column name and value
  - Row.as_list() returns list of values
  - Row.as_tuple() returns tuple of values
- Fix segfault when select list of udt with null values
- Fix bind map type and add more tests

0.1.5a0
========
- Support for for all native types.
- Method `as_dict` to row object
- Add support for collections types, tuple and udt
- Add batch counter

0.1.4a0
========
-  Support for Python 3.9

0.1.3a0
=======
- Expose the c++ library error definitions as python exceptions
- UUID: bindings and value method.
- Add support for configuring a timeout during cluster, statement, prepared and batch creation time. Timeouts
are expressed in seconds.
- Add support for returning metrics related to a Session. Returned metrics are latencies, rates and statistics.
- Add support for configuring the consistency at cluster, statement and prepared level.

0.1.2a0
=======
- Wheel support for MacOS

0.1.1a0
=======
- Fix Python 3.8 wheel. Use manylinux2010 for compiling the packages
- Support for paging. Now we can set the page size of the statements - preared or not prepared - and later on
provide a token for fethcing the next page [#30](https://github.com/pfreixes/acsylla/pull/30)

0.1.0a0
=======
Alpha release for getting feedback from the comunity, the driver is not yet production ready but
comes with the minimal stuff for testing it.

0.1.5a0
========
- Support for for all native types.
- Method `as_dict` to row object
- Add support for collections types, tuple and udt
- Add batch counter

0.1.4a0
========
-  Support for Python 3.9

0.1.3a0
=======
- Expose the c++ library error definitions as python exceptions
- UUID: bindings and value method.
- Add support for configuring a timeout during cluster, statement, prepared and batch creation time. Timeouts
are expressed in seconds.
- Add support for returning metrics related to a Session. Returned metrics are latencies, rates and statistics.
- Add support for configuring the consistency at cluster, statement and prepared level.

0.1.2a0
=======
- Wheel support for MacOS

0.1.1a0
=======
- Fix Python 3.8 wheel. Use manylinux2010 for compiling the packages
- Support for paging. Now we can set the page size of the statements - preared or not prepared - and later on
provide a token for fethcing the next page [#30](https://github.com/pfreixes/acsylla/pull/30)

0.1.0a0
=======
Alpha release for getting feedback from the comunity, the driver is not yet production ready but
comes with the minimal stuff for testing it.**
