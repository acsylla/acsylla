NOT RELEASED YET
================

0.1.8a0
========
- Add metadata support
- Add logging
- Add Blacklist, whitelist DC, and blacklist, whitelist hostd load balancing policies
- Update cpp-driver to latest version
- Static link OpenSSL and libuv for MacOS wheel

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
