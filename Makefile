PYTHON ?= python
PIP ?= pip
CYTHON ?= cython

_default: compile

clean:
	rm -fr acsylla/_cython/*.c acsylla/_cython/*.cpp acsylla/_cython/*.so build dist
	find . -name '__pycache__' | xargs rm -rf
	find . -type f -name "*.pyc" -delete

.install-cython:
	$(PIP) install Cython==0.29.18
	touch .install-cython

acsylla/_cython/cyacsylla.cpp: acsylla/_cython/cyacsylla.pyx
	$(CYTHON) -3 -o $@ $< -I acsylla --cplus

cythonize: .install-cython acsylla/_cython/cyacsylla.cpp

setup-build:
	$(PYTHON) setup.py build_ext --inplace

compile: clean cythonize setup-build

install-dev: compile
	$(PIP) install -e ".[dev]"

install: compile
	$(PIP) install -e .

test: 
	pytest -sv tests


.PHONY: clean setup-build install install-dev compile test
