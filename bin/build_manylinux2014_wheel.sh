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
elif [ $PYTHON_VERSION == "3.10" ]
then
    PYTHON=/opt/python/cp310-cp310/bin/python
    PIP=/opt/python/cp310-cp310/bin/pip
    CYTHON=/opt/python/cp310-cp310/bin/cython
    AUDITWHEEL=/opt/python/cp310-cp310/bin/auditwheel
elif [ $PYTHON_VERSION == "3.11" ]
then
    PYTHON=/opt/python/cp311-cp311/bin/python
    PIP=/opt/python/cp311-cp311/bin/pip
    CYTHON=/opt/python/cp311-cp311/bin/cython
    AUDITWHEEL=/opt/python/cp311-cp311/bin/auditwheel
else
    exit 1
fi

cd /io

yum install cmake -y
yum install openssl openssl-devel -y

LIBUV_VERSION=1.44.2

curl -O https://dist.libuv.org/dist/v$LIBUV_VERSION/libuv-v$LIBUV_VERSION.tar.gz
tar -xzvf libuv-v$LIBUV_VERSION.tar.gz
cd libuv-v$LIBUV_VERSION
sh autogen.sh
./configure
make
make install
cd ..

git config --global --add safe.directory /io

make install-driver

${PYTHON} -m pip install --upgrade pip
${PIP} install auditwheel cython
PYTHON=${PYTHON} PIP=${PIP} CYTHON=${CYTHON} make compile
${PYTHON} setup.py bdist_wheel
${AUDITWHEEL} repair dist/acsylla-*.whl -w dist
rm dist/acsylla-*-linux*
