#!/bin/bash

BRANCH=${1:-master}

echo Build branch $BRANCH

PYTHON=python
PIP=pip
CYTHON=cython

apt update

apt -y install build-essential git cmake libssl-dev libuv1-dev zlib1g-dev
apt -y install libkrb5-dev clang-format pkg-config

git clone https://github.com/acsylla/acsylla.git
cd acsylla
git checkout -b $BRANCH origin/$BRANCH

make install-driver || exit 1

${PYTHON} -m pip install --upgrade pip
${PIP} install auditwheel cython
PYTHON=${PYTHON} PIP=${PIP} CYTHON=${CYTHON} make compile
${PYTHON} setup.py bdist_wheel && cp -R dist/* ../