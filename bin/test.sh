#!/bin/bash

PYTHON=/usr/local/bin/python$PYTHON_VERSION

$PYTHON -m venv /$PYTHON_VERSION
source /$PYTHON_VERSION/bin/activate

cd /io

pip install dist/acsylla-*

pip install -r requirements-test.txt

rm -r acsylla

if [ "$(uname)" == "Darwin" ]; then
  sed -i 's/127\.\0\.0\.1/host\.docker\.internal/g' ./tests/conftest.py
fi

make test