set -x


_main() {
    local tmp=$(mktemp -d)
    echo "TMP DIR: $tmp"
    local patch_file=$tmp/aws-lc.patch
    git checkout 3.10-debugging
    git diff upstream/3.10 >$patch_file

    for branch in 3.7 3.8 3.9 3.10 3.11 3.12 main; do
        git checkout $branch
        local log=$tmp/${branch}_build.log
        if ! patch -f -i $patch_file -p1 &>$log; then
            git reset --hard
            git clean -f
            git clean -fd
            continue
        fi
        make clean
        ./configure \
            --with-openssl=/home/ubuntu/workplace/local-install \
            --with-builtin-hashlib-hashes=blake2 \
            --with-ssl-default-suites=openssl \
            --prefix=/home/ubuntu/workplace/local-install \
            >>$log
        make -j $(nproc) test >>$log
        git reset --hard
        git clean -f
        git clean -fd
    done
    git checkout 3.10-debugging
    echo "TMP DIR: $tmp"
}

_main
