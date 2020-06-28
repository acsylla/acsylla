acsylla
#######


Developing
============

For developing you must clone the respository and first compile the CPP Cassandra driver, please
follow the `instructions <https://docs.datastax.com/en/developer/cpp-driver/2.6/topics/building/>`_
for installing any dependency that you would need for compiling the driver:

.. code-block:: bash

    git clone git@github.com:pfreixes/acsylla.git
    cd ascylla/
    git submodule update --init --recursive
    cd vendor/cpp-driver
    mkdir build
    cd build
    cmake -D CASS_BUILD_STATIC=ON -D CMAKE_CXX_FLAGS=-fPIC -D CASS_BUILD_SHARED=OFF -D CASS_USE_STATIC_LIBS=ON -D CMAKE_C_FLAGS=-fPIC ..
    make

Set up the environment and compile the package using the following commands:

.. code-block:: bash

    python -m venv venv
    source venv/bin/activate
    make compile
    make install-dev

And finnally run the tests:

.. code-block:: bash

    docker run -d -p 9042:9042 -t -i --rm cassandra:latest
    cqlsh --cqlversion=3.4.4 -e "CREATE KEYSPACE IF NOT EXISTS acsylla WITH REPLICATION = { 'class': 'SimpleStrategy', 'replication_factor': 1}"
    cqlsh --cqlversion=3.4.4 -k "acsylla" -e "CREATE TABLE IF NOT EXISTS test(id int PRIMARY KEY, value int)"
    make test
