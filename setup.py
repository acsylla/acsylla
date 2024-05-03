from setuptools import Extension
from setuptools import setup
from setuptools.command.build_ext import build_ext

import os
import re
import sys

if sys.platform in ("win32", "cygwin", "cli"):
    raise RuntimeError("acsylla does not support Windows at the moment")

vi = sys.version_info
if vi < (3, 7):
    raise RuntimeError("acsylla requires Python 3.7 or greater")

CPP_CASSANDRA_DIR = os.path.join("vendor", "cpp-driver")
CPP_CASSANDRA_INCLUDE_DIR = os.path.join(CPP_CASSANDRA_DIR, "include")
CPP_CASSANDRA_STATIC_LIB_DIR = os.path.join(CPP_CASSANDRA_DIR, "build", "libscylla-cpp-driver_static.a")

extension = Extension(
    "acsylla._cython.cyacsylla",
    sources=["acsylla/_cython/cyacsylla.cpp"],
    include_dirs=[CPP_CASSANDRA_INCLUDE_DIR],
    extra_objects=[CPP_CASSANDRA_STATIC_LIB_DIR],
    extra_compile_args=["-std=c++14"],
    libraries=["crypto", "ssl", "uv", "z"],
)


class acsylla_build_ext(build_ext):
    def build_extensions(self):
        ssl_path = os.environ.get("SSL_LIBRARY_PATH")
        if os.sys.platform == "darwin" and ssl_path is not None:
            extension.extra_objects.append(os.path.join(ssl_path, "libssl.a"))
            extension.extra_objects.append(os.path.join(ssl_path, "libcrypto.a"))
            extension.libraries.remove("ssl")
            extension.libraries.remove("crypto")
        libuv_path = os.environ.get("UV_LIBRARY_PATH")
        if os.sys.platform == "darwin" and libuv_path is not None:
            extension.extra_objects.append(os.path.join(libuv_path, "libuv.a"))
            extension.libraries.remove("uv")
        super().build_extensions()


dev_requires = [
    "Cython==0.29.33",
    "pytest==6.2.5",
    "pytest-mock==3.6.1",
    "pytest-asyncio==0.16.0",
    "asynctest==0.13.0",
    "pytest-cov==3.0.0",
    "black==22.8.0",
    "click==8.1.3",
    "isort==5.9.3",
    "flake8==4.0.1",
    "mypy==0.910",
    "setuptools"
]


def get_version():
    with open(os.path.join(os.path.abspath(os.path.dirname(__file__)), "acsylla/version.py")) as fp:
        try:
            return re.findall(r"^__version__ = \"([^']+)\"\r?$", fp.read())[0]
        except IndexError:
            raise RuntimeError("Unable to determine version.")


with open(os.path.join(os.path.dirname(__file__), "README.md")) as f:
    readme = f.read()

setup(
    version=get_version(),
    name="acsylla",
    description="A high performance asynchronous Cassandra and ScyllaDB client",
    long_description=readme,
    long_description_content_type="text/markdown",
    url="http://github.com/acsylla/acsylla",
    author="Pau Freixes",
    author_email="pfreixes@gmail.com",
    platforms=["*nix"],
    packages=["acsylla"],
    cmdclass={"build_ext": acsylla_build_ext},
    ext_modules=[extension],
    extras_require={"dev": dev_requires},
    classifiers=[
        "Development Status :: 4 - Beta",
        "Programming Language :: Python :: 3 :: Only",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "License :: OSI Approved :: Apache Software License",
        "License :: OSI Approved :: MIT License",
        "Intended Audience :: Developers",
    ],
)
