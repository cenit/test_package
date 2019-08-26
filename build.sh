#!/usr/bin/env bash

number_of_build_workers=8
bypass_vcpkg=false
vcpkg_fork=""
#install_prefix="-DCMAKE_INSTALL_PREFIX=.."

if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ "$1" == "gcc" ]]; then
    export CC="/usr/local/bin/gcc-9"
    export CXX="/usr/local/bin/g++-9"
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
  (>&2 echo "VideoLoop is unsupported without vcpkg, use at your own risk!")
fi

## DEBUG
#mkdir -p build_debug
#cd build_debug
#cmake -DCMAKE_BUILD_TYPE=Debug ${vcpkg_define} ${vcpkg_triplet_define} ${additional_defines} ${additional_build_setup} ${install_prefix} ..
#cmake --build . --parallel ${number_of_build_workers}
#cd ..

# RELEASE
mkdir -p build_release
cd build_release
cmake -DCMAKE_BUILD_TYPE=Release ${vcpkg_define} ${vcpkg_triplet_define} ${additional_defines} ${additional_build_setup} ${install_prefix} ..
cmake --build . --parallel ${number_of_build_workers}
cd ..
