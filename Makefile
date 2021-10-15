PYTHON ?= python
PIP ?= pip
CYTHON ?= cython
current_dir = $(shell pwd)

_default: compile

clean:
	rm -fr acsylla/_cython/*.c acsylla/_cython/*.cpp acsylla/_cython/*.so build dist certs
	find . -name '__pycache__' | xargs rm -rf
	find . -type f -name "*.pyc" -delete

.install-cython:
	$(PIP) install cython
	touch .install-cython

acsylla/_cython/cyacsylla.cpp: acsylla/_cython/cyacsylla.pyx
	$(CYTHON) -3 -o $@ $< -I acsylla --cplus

cythonize: .install-cython acsylla/_cython/cyacsylla.cpp

setup-build:
	$(PYTHON) setup.py build_ext --inplace

compile: clean cythonize setup-build

install-driver:
	git submodule update --init --recursive
	mkdir -p $(current_dir)/vendor/cpp-driver/build
	cd $(current_dir)/vendor/cpp-driver/build && \
		cmake -D CASS_BUILD_STATIC=ON -D CMAKE_CXX_FLAGS=-fPIC -D CASS_BUILD_SHARED=OFF -D CASS_USE_STATIC_LIBS=ON -D CMAKE_C_FLAGS=-fPIC .. && \
		make

install-dev: compile
	$(PIP) install -e ".[dev]"

install: compile
	$(PIP) install -e .

format:
	isort --recursive .
	black .

lint:
	isort --check-only --recursive .
	black --exclude vendor --check .
	flake8 --config setup.cfg

mypy:
	mypy -p acsylla -p tests.test_typing

test:
	pytest -v tests

stress: 
	python benchmark/acsylla_benchmark.py --duration 10 --concurrency 32

certs:
	bin/make_test_certs.sh

.PHONY: clean setup-build install install-dev compile test stress mypy lint format certs
