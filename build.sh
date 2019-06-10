#!/usr/bin/env bash

bypass_vcpkg=false
vcpkg_fork="_opencv4"

if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ "$1" == "gcc" ]]; then
    export CC="/usr/local/bin/gcc-8"
    export CXX="/usr/local/bin/g++-8"
  fi
  vcpkg_triplet="x64-osx"
else
  vcpkg_triplet="x64-linux"
fi

if [[ ! -z "${VCPKG_ROOT}" ]] && [ -d ${VCPKG_ROOT}${vcpkg_fork} ] && [ ! "$bypass_vcpkg" = true ]
then
  vcpkg_path="${VCPKG_ROOT}${vcpkg_fork}"
  vcpkg_define="-DCMAKE_TOOLCHAIN_FILE=${vcpkg_path}/scripts/buildsystems/vcpkg.cmake"
  vcpkg_triplet_define="-DVCPKG_TARGET_TRIPLET=$vcpkg_triplet"
  echo "Found vcpkg in VCPKG_ROOT: ${vcpkg_path}"
elif [[ ! -z "${WORKSPACE}" ]] && [ -d ${WORKSPACE}/vcpkg${vcpkg_fork} ] && [ ! "$bypass_vcpkg" = true ]
then
  vcpkg_path="${WORKSPACE}/vcpkg${vcpkg_fork}"
  vcpkg_define="-DCMAKE_TOOLCHAIN_FILE=${vcpkg_path}/scripts/buildsystems/vcpkg.cmake"
  vcpkg_triplet_define="-DVCPKG_TARGET_TRIPLET=$vcpkg_triplet"
  echo "Found vcpkg in WORKSPACE/vcpkg${vcpkg_fork}: ${vcpkg_path}"
elif [ ! "$bypass_vcpkg" = true ]
then
  (>&2 echo "test is unsupported without vcpkg, use at your own risk!")
fi

# RELEASE
mkdir -p build_release
cd build_release
cmake .. -DCMAKE_BUILD_TYPE=Release ${vcpkg_define} ${vcpkg_triplet_define} ${additional_defines} ${additional_build_setup}
#cmake --build .
make VERBOSE=1
cd ..
