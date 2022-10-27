#!/bin/sh

set -x

SCRIPT_DIR=`dirname $0`
PYTHON_VERSION=${1:-3.11}
BRANCH=${2:-master}
ARCH=${3:-x86_64} # x86_64 or aarch64
BUILD_DIR=${4:-"ACSYLLA_BUILD-Python-$PYTHON_VERSION-$ARCH"}

echo Build driver for Python $PYTHON_VERSION $ARCH working directory $BUILD_DIR

DOCKER_CMD="docker"
WORK_DIR=`pwd`
MOUNT_POINT="/build"
NAME="acsylla_build_$PYTHON_VERSION-$ARCH"

case $ARCH in
  aarch64|amd64) IMAGE="arm64v8/python:$PYTHON_VERSION-bullseye";;
  *) IMAGE="python:$PYTHON_VERSION-slim";;
esac

read -p 'Press Enter to continue...'

mkdir $BUILD_DIR && cp $SCRIPT_DIR/build.sh $BUILD_DIR && cd $BUILD_DIR || exit 1

$DOCKER_CMD run -it --rm -v $WORK_DIR:$MOUNT_POINT --name $NAME $IMAGE /bin/sh -c "cd ${MOUNT_POINT} && sh ./build.sh ${BRANCH}"
