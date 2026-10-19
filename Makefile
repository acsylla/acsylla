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

JEMALLOC_VERSION = 5.3.0
JEMALLOC_SHA256 = 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa
JEMALLOC_DIR = $(current_dir)/vendor/jemalloc-$(JEMALLOC_VERSION)
# jemalloc does not start on a system with larger pages than it was built for, every allocation
# fails. Linux on aarch64 has 4K, 16K or 64K pages and the wheels are built on 4K, so they are
# built for 64K pages.
ifeq ($(shell uname -s)-$(shell uname -m),Linux-aarch64)
JEMALLOC_LG_PAGE = --with-lg-page=16
endif

install-jemalloc:
	test -f $(JEMALLOC_DIR)/lib/libjemalloc_pic.a || ( \
		cd $(current_dir)/vendor && \
		curl -sSLO https://github.com/jemalloc/jemalloc/releases/download/$(JEMALLOC_VERSION)/jemalloc-$(JEMALLOC_VERSION).tar.bz2 && \
		$(PYTHON) -c "import hashlib, sys; sys.exit(hashlib.sha256(open('jemalloc-$(JEMALLOC_VERSION).tar.bz2', 'rb').read()).hexdigest() != '$(JEMALLOC_SHA256)')" && \
		tar -xjf jemalloc-$(JEMALLOC_VERSION).tar.bz2 && \
		rm jemalloc-$(JEMALLOC_VERSION).tar.bz2 && \
		cd $(JEMALLOC_DIR) && \
		./configure --with-jemalloc-prefix=acsylla_je_ --with-private-namespace=acsylla_je_ --without-export \
			--disable-cxx --disable-libdl --disable-initial-exec-tls --disable-zone-allocator $(JEMALLOC_LG_PAGE) && \
		$(MAKE) build_lib_static EXTRA_CFLAGS=-g0)

install-driver: install-jemalloc
	git submodule update --init --recursive
	patch -N -p0 < vendor/std-move.patch || echo Already applied
	patch -N -p0 < vendor/prevent-stdout-spam.patch || echo Already applied
	patch -N -p0 < vendor/unquote-udt-name.patch || echo Already applied
	patch -N -p0 < vendor/openssl4-const.patch || echo Already applied
	patch -N -p0 < vendor/jemalloc-allocator.patch || echo Already applied
	patch -N -p0 < vendor/routing-key-token.patch || echo Already applied
	patch -N -p0 < vendor/coalesce-wakeup.patch || echo Already applied
	patch -N -p0 < vendor/tablets-routing.patch || echo Already applied
	patch -N -p0 < vendor/connect-shards-now.patch || echo Already applied
	patch -N -p0 < vendor/pool-learns-shards.patch || echo Already applied
	patch -N -p0 < vendor/node-address-change.patch || echo Already applied
	patch -N -p0 < vendor/trusted-cert-bundle.patch || echo Already applied
	patch -N -p0 < vendor/tls13.patch || echo Already applied
	mkdir -p $(current_dir)/vendor/cpp-driver/build
	cd $(current_dir)/vendor/cpp-driver/build && \
		cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -D CASS_BUILD_STATIC=ON -D CMAKE_CXX_FLAGS="-fPIC -flto" -D CASS_BUILD_SHARED=OFF -D CASS_USE_STATIC_LIBS=ON -D CMAKE_C_FLAGS="-fPIC -flto" -D CMAKE_INTERPROCEDURAL_OPTIMIZATION=ON -D CMAKE_BUILD_TYPE=Release .. && \
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

.PHONY: clean setup-build install install-dev install-jemalloc compile test stress mypy lint format certs
