from setuptools import Extension
from setuptools import setup

import os
import re
import sys

if sys.platform in ("win32", "cygwin", "cli"):
    raise RuntimeError("acsylla does not support Windows at the moment")

vi = sys.version_info
if vi < (3, 7):
    raise RuntimeError("acsylla requires Python 3.7 or greater")

CPP_CASSANDRA_DIR = os.path.join(os.path.dirname(__file__), "vendor", "cpp-driver")
CPP_CASSANDRA_INCLUDE_DIR = os.path.join(CPP_CASSANDRA_DIR, "include")
CPP_CASSANDRA_STATIC_LIB_DIR = os.path.join(CPP_CASSANDRA_DIR, "build", "libscylla-cpp-driver_static.a")

extensions = [
    Extension(
        "acsylla._cython.cyacsylla",
        sources=["acsylla/_cython/cyacsylla.cpp"],
        include_dirs=[CPP_CASSANDRA_INCLUDE_DIR],
        extra_objects=[CPP_CASSANDRA_STATIC_LIB_DIR],
        extra_compile_args=["-std=c++11"],
        libraries=["crypto", "ssl", "uv", "z"],
    )
]

dev_requires = [
    "Cython==0.29.18",
    "pytest==5.4.1",
    "pytest-mock==3.1.0",
    "pytest-asyncio==0.11.0",
    "asynctest==0.13.0",
    "pytest-cov==2.8.1",
    "black==19.10b0",
    "isort==4.3.21",
    "flake8==3.7.9",
    "mypy==0.782",
]


def get_version():
    with open(os.path.join(os.path.abspath(os.path.dirname(__file__)), "acsylla/version.py")) as fp:
        try:
            return re.findall(r"^__version__ = \"([^']+)\"\r?$", fp.read())[0]
        except IndexError:
            raise RuntimeError("Unable to determine version.")


with open(os.path.join(os.path.dirname(__file__), "README.rst")) as f:
    readme = f.read()

setup(
    version=get_version(),
    name="acsylla",
    description="A high performance asynchronous Cassandra and Scylla client",
    long_description=readme,
    url="http://github.com/pfreixes/acsylla",
    author="Pau Freixes",
    author_email="pfreixes@gmail.com",
    platforms=["*nix"],
    packages=["acsylla"],
    ext_modules=extensions,
    extras_require={"dev": dev_requires},
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Programming Language :: Python :: 3 :: Only",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "License :: OSI Approved :: Apache Software License",
        "License :: OSI Approved :: MIT License",
        "Intended Audience :: Developers",
    ],
)
