#!/usr/bin/env bash

set -e

UPYTH_VER="1.15"
UPYTH="micropython-${UPYTH_VER}"
PKG_URL="https://github.com/micropython/micropython/releases/download/v${UPYTH_VER}/${UPYTH}.tar.xz"
PKG_MIRROR_URL="https://files.phoesys.com/ports/${UPYTH}.tar.xz"

PREFIX_UPYTH="${PREFIX_PROJECT}/phoenix-rtos-ports/micropython"
PREFIX_UPYTH_BUILD="${PREFIX_BUILD}/micropython"
PREFIX_UPYTH_SRC=${PREFIX_UPYTH_BUILD}/${UPYTH}
PREFIX_UPYTH_CONFIG="${PREFIX_UPYTH}/${UPYTH}-config/"
PREFIX_UPYTH_MARKERS="$PREFIX_UPYTH_BUILD/markers/"

# Prefixes for micropython tests
PREFIX_UPYTH_TESTS_SRC="${PREFIX_UPYTH_SRC}/tests"
PREFIX_UPYTH_TESTS_DES="${PREFIX_ROOTFS}/usr/test/micropython"

# Directories in micropython test/ directory from which tests are sourced
UPYTH_TESTS_DIRS="basics micropython float import io misc unicode extmod unix cmdline"

b_log "Building micropython"

#
# Download and unpack
#
mkdir -p "$PREFIX_UPYTH_BUILD" "$PREFIX_UPYTH_MARKERS"
if [ ! -f "$PREFIX_UPYTH/${UPYTH}.tar.xz" ]; then
	if ! wget "$PKG_URL" -P "${PREFIX_UPYTH}" --no-check-certificate; then
		wget "$PKG_MIRROR_URL" -P "${PREFIX_UPYTH}" --no-check-certificate
	fi
fi
[ -d "${PREFIX_UPYTH_SRC}" ] || tar xf "$PREFIX_UPYTH/${UPYTH}.tar.xz" -C "$PREFIX_UPYTH_BUILD"


#
# Apply patches and copy files
#
for patchfile in "$PREFIX_UPYTH_CONFIG"/patches/*.patch; do
	if [ ! -f "$PREFIX_UPYTH_MARKERS/$(basename "$patchfile").applied" ]; then
		echo "applying patch: $patchfile"
		patch -d "$PREFIX_UPYTH_SRC" -p1 < "$patchfile"
		touch "$PREFIX_UPYTH_MARKERS/$(basename "$patchfile").applied"
	fi
done
cp -a "${PREFIX_UPYTH_CONFIG}/files/001_mpconfigport.mk" "${PREFIX_UPYTH_SRC}/ports/unix/mpconfigport.mk" && echo "Copied mpconfigport.mk!"


#
# Micropython internal use stack/heap size (not actual application stack/heap)
# Values are to be overwritten in _targets/build.project.*
#
: "${UPYTH_STACKSZ=4096}"
: "${UPYTH_HEAPSZ=16384}"

# Some micropython tests needs more memory
if [ "$LONG_TEST" = "y" ]; then
	UPYTH_STACKSZ=16384
	UPYTH_HEAPSZ=80000
fi

#
# Architecture specific flags/values set
#
if [ "${TARGET_FAMILY}" = "armv7m7" ]; then
	STRIPEXP="--strip-unneeded"
elif [ "${TARGET_FAMILY}" = "ia32" ]; then
	STRIPEXP="--strip-all"
else
	b_log "Warning! Phoenix-RTOS for ${TARGET_FAMILY} does not support MicroPython compilation (yet!)"
	b_log "The compilation attempt will start in 5 seconds..."
	sleep 5
fi
export STRIPFLAGS_EXTRA="${STRIPEXP}"
export PHOENIX_MATH_ABSENT="expm1 log1p asinh acosh atanh erf tgamma lgamma copysign __sin __cos __tan __signbit"
export LDFLAGS_EXTRA="${CFLAGS} ${LDFLAGS}"
export CFLAGS_EXTRA="${CFLAGS} -DUPYTH_STACKSZ=${UPYTH_STACKSZ} -DUPYTH_HEAPSZ=${UPYTH_HEAPSZ} "
# clear original ld-format ldflags/cflags
export LDFLAGS=""
export CFLAGS=""


#
# Build and install micropython binary
#
(cd "${PREFIX_UPYTH_SRC}/mpy-cross" && make all BUILD="${PREFIX_UPYTH_BUILD}" CROSS_COMPILE="${CROSS}")
(cd "${PREFIX_UPYTH_SRC}/ports/unix" && make all CROSS_COMPILE="${CROSS}")

cp -a "${PREFIX_UPYTH_SRC}/ports/unix/micropython" "$PREFIX_PROG_STRIPPED"
b_install "$PREFIX_PORTS_INSTALL/micropython" /bin/

#
# Copy tests for micropython
#
if [ "$LONG_TEST" = "y" ]; then
	echo "Copying micropython tests"

	# Creating expected outputs for tests
	(cd "${PREFIX_UPYTH_TESTS_SRC}" && ./run-tests.py --write-exp)

	mkdir -p "$PREFIX_UPYTH_TESTS_DES"

	for dir in $UPYTH_TESTS_DIRS
	do
		cp -r "$PREFIX_UPYTH_TESTS_SRC/$dir" "$PREFIX_UPYTH_TESTS_DES"
	done

	# Copying expected outputs for tests, which differs from these generated by CPython
	cp -r "$PREFIX_UPYTH/exp_prefabs/." "$PREFIX_UPYTH_TESTS_DES"
fi