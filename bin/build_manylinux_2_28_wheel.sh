#!/bin/bash

set -x

PYTHON=/usr/local/bin/python$PYTHON_VERSION

$PYTHON -m venv /$PYTHON_VERSION
source /$PYTHON_VERSION/bin/activate

cd /io

dnf install openssl-devel -y

LIBUV_VERSION=1.48.0

curl -O https://dist.libuv.org/dist/v$LIBUV_VERSION/libuv-v$LIBUV_VERSION.tar.gz
tar -xzvf libuv-v$LIBUV_VERSION.tar.gz
cd libuv-v$LIBUV_VERSION
sh autogen.sh
./configure
make
make install
cd ..

git config --global --add safe.directory /io

export LIBUV_ROOT_DIR="/usr/local"

make install-driver

python -m pip install --upgrade pip
python -m pip install auditwheel cython setuptools wheel
make compile
python setup.py bdist_wheel
auditwheel repair dist/acsylla-*.whl -w dist
rm dist/acsylla-*-linux*
