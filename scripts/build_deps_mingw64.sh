#!/bin/bash -e

# Cross-compilation script for xmrig dependencies (Linux -> Windows x64)
# Prerequisites: mingw-w64 g++-mingw-w64-x86-64 cmake wget autoconf automake libtool

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPS_DIR="${SCRIPT_DIR}/../deps-mingw64"
BUILD_DIR="${SCRIPT_DIR}/../build-deps-mingw64"

CROSS_PREFIX="x86_64-w64-mingw32"
CROSS_HOST="x86_64-w64-mingw32"

UV_VERSION="1.48.0"
HWLOC_VERSION="2.10.0"
OPENSSL_VERSION="3.2.1"

NPROC=$(nproc 2>/dev/null || echo 4)

echo "Building dependencies for Windows x64 cross-compilation"
echo "Output directory: ${DEPS_DIR}"
echo ""

mkdir -p "${DEPS_DIR}/include"
mkdir -p "${DEPS_DIR}/lib"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# ========== libuv ==========
echo "=== Building libuv ${UV_VERSION} ==="
if [ ! -f "${DEPS_DIR}/lib/libuv.a" ]; then
    if [ ! -f "libuv-v${UV_VERSION}.tar.gz" ]; then
        wget "https://dist.libuv.org/dist/v${UV_VERSION}/libuv-v${UV_VERSION}.tar.gz"
    fi
    rm -rf "libuv-v${UV_VERSION}"
    tar -xzf "libuv-v${UV_VERSION}.tar.gz"
    cd "libuv-v${UV_VERSION}"

    mkdir -p build && cd build
    cmake .. \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER=${CROSS_PREFIX}-gcc \
        -DCMAKE_CXX_COMPILER=${CROSS_PREFIX}-g++ \
        -DCMAKE_RC_COMPILER=${CROSS_PREFIX}-windres \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIBUV_BUILD_SHARED=OFF \
        -DLIBUV_BUILD_TESTS=OFF

    make -j${NPROC}

    cp -f libuv.a "${DEPS_DIR}/lib/"
    cp -fr ../include/* "${DEPS_DIR}/include/"
    cd "${BUILD_DIR}"
    echo "libuv built successfully"
else
    echo "libuv already built, skipping"
fi

# ========== hwloc ==========
echo ""
echo "=== Building hwloc ${HWLOC_VERSION} ==="
if [ ! -f "${DEPS_DIR}/lib/libhwloc.a" ]; then
    if [ ! -f "hwloc-${HWLOC_VERSION}.tar.gz" ]; then
        wget "https://download.open-mpi.org/release/hwloc/v2.10/hwloc-${HWLOC_VERSION}.tar.gz"
    fi
    rm -rf "hwloc-${HWLOC_VERSION}"
    tar -xzf "hwloc-${HWLOC_VERSION}.tar.gz"
    cd "hwloc-${HWLOC_VERSION}"

    ./configure \
        --host=${CROSS_HOST} \
        --disable-shared \
        --enable-static \
        --disable-io \
        --disable-libudev \
        --disable-libxml2 \
        --disable-cairo \
        --disable-opencl \
        --disable-cuda \
        --disable-nvml \
        --disable-rsmi \
        --disable-levelzero \
        --disable-gl \
        --disable-plugins \
        CC=${CROSS_PREFIX}-gcc \
        CXX=${CROSS_PREFIX}-g++ \
        CFLAGS="-O2" \
        CXXFLAGS="-O2"

    make -j${NPROC}

    cp -f hwloc/.libs/libhwloc.a "${DEPS_DIR}/lib/"
    mkdir -p "${DEPS_DIR}/include/hwloc"
    cp -f include/hwloc.h "${DEPS_DIR}/include/"
    cp -fr include/hwloc/*.h "${DEPS_DIR}/include/hwloc/"
    cd "${BUILD_DIR}"
    echo "hwloc built successfully"
else
    echo "hwloc already built, skipping"
fi

# ========== OpenSSL ==========
echo ""
echo "=== Building OpenSSL ${OPENSSL_VERSION} ==="
if [ ! -f "${DEPS_DIR}/lib/libssl.a" ]; then
    if [ ! -f "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
        wget "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    fi
    rm -rf "openssl-${OPENSSL_VERSION}"
    tar -xzf "openssl-${OPENSSL_VERSION}.tar.gz"
    cd "openssl-${OPENSSL_VERSION}"

    ./Configure mingw64 \
        --cross-compile-prefix=${CROSS_PREFIX}- \
        no-shared \
        no-asm \
        no-zlib \
        no-comp \
        no-dgram \
        no-dso \
        no-engine \
        --prefix="${DEPS_DIR}"

    make -j${NPROC}
    make install_sw

    cd "${BUILD_DIR}"
    echo "OpenSSL built successfully"
else
    echo "OpenSSL already built, skipping"
fi

echo ""
echo "========================================"
echo "Dependencies built successfully!"
echo "Output directory: ${DEPS_DIR}"
echo ""
echo "To build xmrig for Windows:"
echo "  mkdir build-win64 && cd build-win64"
echo "  cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-mingw64.cmake -DXMRIG_DEPS=${DEPS_DIR}"
echo "  make -j\$(nproc)"
echo "========================================"
