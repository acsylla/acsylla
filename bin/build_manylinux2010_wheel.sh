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
elif [ $PYTHON_VERSION == "3.9" ]
then
    PYTHON=/opt/python/cp39-cp39/bin/python
    PIP=/opt/python/cp39-cp39/bin/pip
    CYTHON=/opt/python/cp39-cp39/bin/cython
    AUDITWHEEL=/opt/python/cp39-cp39/bin/auditwheel
else
    exit 1
fi

cd /io

yum install cmake -y
yum install wget -y
yum install openssl openssl-devel -y

# We need to download the libuv library and compile it
wget --no-check-certificate https://dist.libuv.org/dist/v1.9.1/libuv-v1.9.1.tar.gz
tar -xzvf libuv-v1.9.1.tar.gz
cd libuv-v1.9.1
sh autogen.sh
./configure
make
make install
cd ..

# We compile the driver by hand becuase for an unkown reason
# we have to provide the following extra flags during the compilatio within
# the manylinux environment
git submodule update --init --recursive
mkdir -p vendor/cpp-driver/build
cd vendor/cpp-driver/build
cmake -D CASS_BUILD_STATIC=ON -D CMAKE_CXX_FLAGS=-fPIC -D CASS_BUILD_SHARED=OFF -D CASS_USE_STATIC_LIBS=ON -D CMAKE_C_FLAGS=-fPIC ..
make
cd ../../..

${PYTHON} -m pip install --upgrade pip
${PIP} install auditwheel
PYTHON=${PYTHON} PIP=${PIP} CYTHON=${CYTHON} make compile
${PYTHON} setup.py bdist_wheel
${AUDITWHEEL} repair dist/acsylla-*.whl -w dist
rm dist/acsylla-*-linux*
