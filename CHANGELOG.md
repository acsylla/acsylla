NOT RELEASED YET
================
nothing new

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
