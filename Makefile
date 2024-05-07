PYTHON ?= python3
PIP ?= pip3
CYTHON ?= cython
current_dir = $(shell pwd)

_default: compile

clean:
	rm -fr acsylla/_cython/cyacsylla.cpp acsylla/_cython/*.so build dist
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
	patch -N -p0 < vendor/std-move.patch || echo Already applied
	patch -N -p0 < vendor/prevent-stdout-spam.patch || echo Already applied
	mkdir -p $(current_dir)/vendor/cpp-driver/build
	cd $(current_dir)/vendor/cpp-driver/build && \
		cmake -D CASS_BUILD_STATIC=ON -D CMAKE_CXX_FLAGS=-fPIC -D CASS_BUILD_SHARED=OFF -D CASS_USE_STATIC_LIBS=ON -D CMAKE_C_FLAGS=-fPIC .. && \
		make

install-dev: compile
	$(PYTHON) -m pip install -e ".[dev]"

install: compile
	$(PIP) install -e .

format:
	isort .
	black .

lint:
	isort --check-only ./acsylla
	black --exclude vendor --check ./acsylla

mypy:
	mypy -p acsylla -p tests.test_typing

test:
	pytest -v tests

stress: 
	python benchmark/acsylla_benchmark.py --duration 10 --concurrency 32

certs:
	bin/make_test_certs.sh

install-doc:
	$(PIP) install -r docs/requirements.txt

doc:
	rm -rf docs/_build
	make -C docs/ html

.PHONY: clean setup-build install install-dev compile test stress mypy lint format certs
