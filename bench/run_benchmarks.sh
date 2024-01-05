#!/usr/bin/env bash

set -exuo pipefail


BENCH_DIR=$(realpath ./bench)
SCRATCH_DIR=$BENCH_DIR/scratch
mkdir -p $SCRATCH_DIR

function setup_vars() {
    SCRATCH_DIR_OSSL=$SCRATCH_DIR/${1}
    SRC_DIR=$SCRATCH_DIR_OSSL/src
    INSTALL_DIR=$SCRATCH_DIR_OSSL/install
    BUILD_DIR=$SCRATCH_DIR_OSSL/build
    mkdir -p $SCRATCH_DIR_OSSL $SRC_DIR $INSTALL_DIR $BUILD_DIR
}

setup_vars aws-lc

[[ -f ${SRC_DIR}/README.md ]] \
    || git clone \
        --branch libssl-handle-EAGAIN \
        https://github.com/WillChilds-Klein/aws-lc.git \
        $SRC_DIR

cmake \
    -B${BUILD_DIR} \
    -S${SRC_DIR} \
    -DCMAKE_BUILD_TYPE=Release\
    -DCMAKE_PREFIX_PATH=${INSTALL_DIR} \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DBUILD_LIBSSL=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF
make -C ${BUILD_DIR} -j $(nproc) install


sed -i -e "s|^OPENSSL=.*$|OPENSSL=${INSTALL_DIR}|g" ./Modules/Setup
./configure \
    --with-openssl=${INSTALL_DIR} \
    --with-builtin-hashlib-hashes=blake2 \
    --with-ssl-default-suites=openssl \
    --prefix=${INSTALL_DIR}
make -j$(nproc)

./python $BENCH_DIR/benchmarks.py
