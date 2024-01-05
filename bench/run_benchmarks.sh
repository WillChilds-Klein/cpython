#!/usr/bin/env bash

set -exuo pipefail


BENCH_DIR=$(realpath ./bench)
SCRATCH_DIR=$BENCH_DIR/scratch
REPORT_FILE=$BENCH_DIR/report.txt

function setup() {
    local repo=${1}
    local branch=${2}
    local dir_name=$(echo -n $repo | cut -d/ -f2)-${branch}

    # these are intentionally global
    SCRATCH_DIR_OSSL=$SCRATCH_DIR/${dir_name}
    SRC_DIR=$SCRATCH_DIR_OSSL/src
    INSTALL_DIR=$SCRATCH_DIR_OSSL/install
    mkdir -p $SCRATCH_DIR_OSSL $SRC_DIR $INSTALL_DIR

    # this assumes all sources managed under git
    [[ -d ${SRC_DIR}/.git ]] \
        || git clone \
            --depth 1 \
            --branch ${branch} \
            https://github.com/${repo}.git \
            $SRC_DIR
}

function build_awslc() {
    pushd $SRC_DIR
    local fips=${1:-"OFF"}
    local build_dir=./build
    cmake \
        -B${build_dir} \
        -S${SRC_DIR} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH=${INSTALL_DIR} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DFIPS=$fips \
        -DBUILD_LIBSSL=ON \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTING=OFF
    make -C ${build_dir} -j $(nproc) install
    popd
}

function build_openssl() {
    pushd ${SRC_DIR}
    ./config \
        --prefix=${INSTALL_DIR} \
        --openssldir=${INSTALL_DIR} \
        -d
    make -j$(nproc)
    make install_sw
    # some systems install under "lib64" instead of "lib", so ensure both
    [[ -d ${INSTALL_DIR}/lib64 ]] || ln -s ${INSTALL_DIR}/lib{,64}
    [[ -d ${INSTALL_DIR}/lib   ]] || ln -s ${INSTALL_DIR}/lib{64,}
    popd
}

function build_python() {
    sed -i -e "s|^OPENSSL=.*$|OPENSSL=${INSTALL_DIR}|g" ./Modules/Setup
    ./configure \
        --with-openssl=${INSTALL_DIR} \
        --with-builtin-hashlib-hashes=blake2 \
        --with-ssl-default-suites=openssl \
        --prefix=${INSTALL_DIR}
    make -j$(nproc)
}

function main() {
    setup WillChilds-Klein/aws-lc libssl-handle-EAGAIN
    build_awslc
    build_python
    ./python $BENCH_DIR/benchmarks.py | tee $REPORT_FILE

    setup openssl/openssl master
    build_openssl
    build_python
    ./python $BENCH_DIR/benchmarks.py |& tee $REPORT_FILE

    setup openssl/openssl OpenSSL_1_1_1-stable
    build_openssl
    build_python
    ./python $BENCH_DIR/benchmarks.py |& tee $REPORT_FILE
}

main
