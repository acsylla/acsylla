#!/bin/sh

set -x

SCRIPT_DIR=`dirname $0`
PYTHON_VERSION=${1:-3.9}
BUILD_DIR=${2:-ACSYLLA_BUILD}

echo Build driver for Python $PYTHON_VERSION working directory $BUILD_DIR

mkdir $BUILD_DIR && cp $SCRIPT_DIR/build.sh $BUILD_DIR && cd $BUILD_DIR || exit 1

DOCKER_CMD="docker"
WORK_DIR=`pwd`
MOUNT_POINT="/build"
NAME="acsylla_build"
IMAGE="python:$PYTHON_VERSION-slim"

BRANCH="use-scylladb-cpp-driver"
$DOCKER_CMD run -it --rm -v $WORK_DIR:$MOUNT_POINT --name $NAME $IMAGE /bin/sh -c "cd ${MOUNT_POINT} && sh ./build.sh ${BRANCH}"
