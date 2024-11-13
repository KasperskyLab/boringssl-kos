#!/usr/bin/env bash
#
# © 2024 AO Kaspersky Lab
# Licensed under the OpenSSL License

set -e

EXAMPLE_DIR="$(dirname "$(realpath "${0}")")"
KOS_DIR="$(realpath "${EXAMPLE_DIR}/../..")"
ROOT_DIR="$(dirname ${KOS_DIR})"
BUILD="${EXAMPLE_DIR}/build"
BUILD_TARGET=

function PrintHelp () {
cat<<HELP

Script to build and run an example of using BoringSSL library for KasperskyOS.

USAGE:
    cross-build.sh [BUILD_TARGET] [-h | --help]

BUILD_TARGET:
    qemu - to build and run the example on QEMU (default value).
    rpi  - to create a file system image called rpi4kos.img for a bootable SD card.
           This image can be directly copied onto an SD card using the dd utility,
           allowing the example to be run on Raspberry Pi.

OPTIONS:
    -h, --help
        Help text.
HELP
}

# Parse arguments.
while [ -n "${1}" ]; do
    case "${1}" in
    -h | --help) PrintHelp
        exit 0;;
    qemu) BUILD_TARGET=sim;;
    rpi) BUILD_TARGET=sd-image;;
    *) echo "Unknown option -'${1}'."
        PrintHelp
        exit 1;;
    esac
    shift
done

if [ -z "${BUILD_TARGET}" ]; then
    echo "Build target is not specified. Default build target is qemu."
    BUILD_TARGET=sim
fi

# Prepare environment.
if [ -z "${SDK_PREFIX}" ]; then
    echo "Can't get path to the installed KasperskyOS SDK."
    echo "Please specify it via the SDK_PREFIX environment variable."
    exit 1
fi

if [ -z "${TARGET}" ]; then
    echo "Target platform is not specified. Try to autodetect..."
    TARGETS=($(ls -d "${SDK_PREFIX}"/sysroot-* | sed 's|.*sysroot-\(.*\)|\1|'))
    if [ ${#TARGETS[@]} -gt 1 ]; then
        echo More than one target platform found: ${TARGETS[*]}.
        echo Use the TARGET environment variable to specify exact platform.
        exit 1
    fi

    export TARGET=${TARGETS[0]}
    echo "Platform ${TARGET} will be used."
fi

export LANG=C
export PKG_CONFIG=""
export PATH="${SDK_PREFIX}/toolchain/bin:${PATH}"

export BUILD_WITH_CLANG=
export BUILD_WITH_GCC=

TOOLCHAIN_SUFFIX=""

if [ "${BUILD_WITH_CLANG}" == "y" ];then
    TOOLCHAIN_SUFFIX="-clang"
fi

if [ "${BUILD_WITH_GCC}" == "y" ];then
    TOOLCHAIN_SUFFIX="-gcc"
fi

"${SDK_PREFIX}/toolchain/bin/cmake" -G "Unix Makefiles" -B "${BUILD}" \
      -D CMAKE_BUILD_TYPE:STRING=Debug \
      -D CMAKE_FIND_ROOT_PATH="${PREFIX_DIR}/sysroot-${TARGET}" \
      -D CMAKE_TOOLCHAIN_FILE="${SDK_PREFIX}/toolchain/share/toolchain-${TARGET}${TOOLCHAIN_SUFFIX}.cmake" \
      "${EXAMPLE_DIR}" && "${SDK_PREFIX}/toolchain/bin/cmake" --build "${BUILD}" -j`nproc` --target ${BUILD_TARGET}
