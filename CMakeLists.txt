cmake_minimum_required(VERSION 2.8)
project(prova C CXX)

#find_package(BLAS)
#find_package(OpenBLAS)
#find_package(LAPACK)
#find_package(LibLZMA REQUIRED NO_MODULE)
#find_package(TIFF)
#find_package(LAPACK CONFIG REQUIRED)

set(protobuf_MODULE_COMPATIBLE ON CACHE BOOL "Enable compatible protobuf symbols")
find_package(protobuf)

#message(STATUS "CLAPACK_FOUND: ${CLAPACK_FOUND}")
#message(STATUS "CLAPACK_VERSION: ${CLAPACK_VERSION}")
#message(STATUS "CLAPACK_LIBRARY: ${CLAPACK_LIBRARY}")
#message(STATUS "LAPACK_LIBRARY: ${LAPACK_LIBRARY}")
#message(STATUS "CLAPACK_INCLUDE_DIR: ${CLAPACK_INCLUDE_DIR}")

#message(STATUS "LibLZMA_FOUND: ${LibLZMA_FOUND}")
#message(STATUS "LibLZMA_LIBRARIES: ${LibLZMA_LIBRARIES}")

message(STATUS "Protobuf_LIBRARIES: ${Protobuf_LIBRARIES}")
message(STATUS "PROTOBUF_LIBRARIES: ${PROTOBUF_LIBRARIES}")
message(STATUS "protobuf_LIBRARIES: ${protobuf_LIBRARIES}")

#add_executable(prova_blas call_blas.c)
#target_include_directories(prova_blas PRIVATE ${BLAS_INCLUDE_DIRS})
#target_link_libraries(prova_blas ${BLAS_LIBRARIES})
#target_link_libraries(prova_blas OpenBLAS::OpenBLAS)

#add_executable(prova_lapack call_lapack.cpp)
#target_link_libraries(prova_lapack ${LAPACK_LIBRARIES})
#target_link_libraries(prova_lapack clapack::clapack)
