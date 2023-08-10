# Building against AWS-LC on Ubuntu 22.02

## Install dependencies

```
$ sudo apt update -y \
    && sudo apt install -y \
        libffi-dev \
        python3 \
        pkg-config
```

## Build and install AWS-LC


```
$ cat $(which cmake-build.sh)
#!/bin/bash

set -ex
set -o pipefail

rm -rf build
mkdir -p build
cd build

pwd

export INSATLL_DIR=${HOME}/workplace/local-install
export CTEST_OUTPUT_ON_FAILURE=1

NPROC=$(nproc)

mkdir -p ${INSATLL_DIR}
cmake \
    -DFIPS=1 \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_PREFIX_PATH=${INSATLL_DIR} \
    -DCMAKE_INSTALL_PREFIX=${INSATLL_DIR} \
    -DCMAKE_VERBOSE_MAKEFILE=1 \
    -DENABLE_DILITHIUM=ON \
    ..

make -j $NPROC 2>&1 | tee build_debug_output.txt
ctest -j $NPROC | tee test_debug_output.txt
make install -j $NPROC

$ mkdir -p ~/workplace/local-install

$ cmake-build.sh
...
```

## Build Python3 against AWS-LC


```
$ git checkout 3.10

$ mkdir build-awslc

$ vim Modules/Setup # set the awslc artifact path as below

$ git diff
diff --git a/Modules/Setup b/Modules/Setup
index 87c6a152f8..5758a8bc56 100644
--- a/Modules/Setup
+++ b/Modules/Setup
@@ -208,7 +208,7 @@ _symtable symtablemodule.c

 # Socket module helper for SSL support; you must comment out the other
 # socket line above, and edit the OPENSSL variable:
-# OPENSSL=/path/to/openssl/directory
+OPENSSL=/home/ubuntu/workplace/local-install/
 # _ssl _ssl.c \
 #     -I$(OPENSSL)/include -L$(OPENSSL)/lib \
 #     -lssl -lcrypto
@@ -217,13 +217,13 @@ _symtable symtablemodule.c
 #     -lcrypto

 # To statically link OpenSSL:
-# _ssl _ssl.c \
-#     -I$(OPENSSL)/include -L$(OPENSSL)/lib \
-#     -l:libssl.a -Wl,--exclude-libs,libssl.a \
-#     -l:libcrypto.a -Wl,--exclude-libs,libcrypto.a
-#_hashlib _hashopenssl.c \
-#     -I$(OPENSSL)/include -L$(OPENSSL)/lib \
-#     -l:libcrypto.a -Wl,--exclude-libs,libcrypto.a
+_ssl _ssl.c \
+     -I$(OPENSSL)/include -L$(OPENSSL)/lib \
+     -l:libssl.a -Wl,--exclude-libs,libssl.a \
+     -l:libcrypto.a -Wl,--exclude-libs,libcrypto.a
+_hashlib _hashopenssl.c \
+     -I$(OPENSSL)/include -L$(OPENSSL)/lib \
+     -l:libcrypto.a -Wl,--exclude-libs,libcrypto.a

 # The crypt module is now disabled by default because it breaks builds
 # on many systems (where -lcrypt is needed), e.g. Linux (I believe).
diff --git a/configure b/configure
index 4b71c4e00f..0c13879b6e 100755
--- a/configure
+++ b/configure
@@ -17873,6 +17873,7 @@ main ()
 {

 /* SSL APIs */
+
 SSL_CTX *ctx = SSL_CTX_new(TLS_client_method());
 SSL_CTX_set_keylog_callback(ctx, keylog_cb);
 SSL *ssl = SSL_new(ctx);
@@ -17881,13 +17882,6 @@ X509_VERIFY_PARAM_set1_host(param, "python.org", 0);
 SSL_free(ssl);
 SSL_CTX_free(ctx);

-/* hashlib APIs */
-OBJ_nid2sn(NID_md5);
-OBJ_nid2sn(NID_sha1);
-OBJ_nid2sn(NID_sha3_512);
-OBJ_nid2sn(NID_blake2b512);
-EVP_PBE_scrypt(NULL, 0, NULL, 0, 2, 8, 1, 0, NULL, 0);
-
   ;
   return 0;
 }

$ ./configure \
        --with-openssl=/home/ubuntu/workplace/local-install \
        --with-builtin-hashlib-hashes=no \
        --prefix /home/ubuntu/workplace/local-install \
    && make -j $(nproc)
...
```
