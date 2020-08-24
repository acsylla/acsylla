#!/bin/bash

if [ $PYTHON_VERSION == "3.7" ]
then
    PYTHON=/opt/python/cp37-cp37m/bin/python
    PIP=/opt/python/cp37-cp37m/bin/pip
    CYTHON=/opt/python/cp37-cp37m/bin/cython
    AUDITWHEEL=/opt/python/cp37-cp37m/bin/auditwheel
elif [ $PYTHON_VERSION == "3.8" ]
then
    PYTHON=/opt/python/cp38-cp38/bin/python
    PIP=/opt/python/cp38-cp38/bin/pip
    CYTHON=/opt/python/cp38-cp38/bin/cython
    AUDITWHEEL=/opt/python/cp38-cp38/bin/auditwheel
else
    exit 1
fi

cd /io

yum install cmake -y
yum install libuv libuv-devel -y
yum install openssl openssl-devel -y

# We compile the driver by hand becuase for an unkown reason
# we have to provide the following extra flags during the compilatio within
# the manylinux environment
# -D LIBUV_LIBRARY=/lib64/libuv.so
git submodule update --init --recursive
mkdir -p vendor/cpp-driver/build
cd vendor/cpp-driver/build
cmake -D CASS_BUILD_STATIC=ON -D CMAKE_CXX_FLAGS=-fPIC -D CASS_BUILD_SHARED=OFF -D CASS_USE_STATIC_LIBS=ON -D CMAKE_C_FLAGS=-fPIC -D LIBUV_LIBRARY=/lib64/libuv.so ..
make
cd ../../..

${PYTHON} -m pip install --upgrade pip
${PIP} install auditwheel
PYTHON=${PYTHON} PIP=${PIP} CYTHON=${CYTHON} make compile
${PYTHON} setup.py bdist_wheel
${AUDITWHEEL} repair dist/acsylla-*.whl -w dist
rm dist/acsylla-*-linux*
