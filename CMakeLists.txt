cmake_minimum_required(VERSION 3.12)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/Modules/" ${CMAKE_MODULE_PATH})

if(DEFINED ENV{VCPKG_DEFAULT_TRIPLET})
  message(STATUS "Setting default vcpkg target triplet to $ENV{VCPKG_DEFAULT_TRIPLET}")
  set(VCPKG_TARGET_TRIPLET $ENV{VCPKG_DEFAULT_TRIPLET})
endif()

if(DEFINED ENV{VCPKG_ROOT} AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
  message(STATUS "VCPKG found: $ENV{VCPKG_ROOT}")
  message(STATUS "Using VCPKG integration")
  message(STATUS "VCPKG_MANIFEST_FEATURES: ${VCPKG_MANIFEST_FEATURES}")
elseif(DEFINED CMAKE_TOOLCHAIN_FILE)
  message(STATUS "Using toolchain: ${CMAKE_TOOLCHAIN_FILE}")
  if(CMAKE_TOOLCHAIN_FILE MATCHES "vcpkg.cmake")
    message(STATUS "Toolchain uses VCPKG integration")
    message(STATUS "VCPKG_MANIFEST_FEATURES: ${VCPKG_MANIFEST_FEATURES}")
  endif()
else()
  message(WARNING "vcpkg not found, toolchain not defined, build might fail")
endif()


project(prova C CXX)


#set(OpenCV_DIR "F:/vcpkg_cenit/installed/x64-windows-release/share/opencv2")
#set(OpenCV_DIR "F:/vcpkg_cenit/installed/x64-windows-release/share/opencv3")
#set(OpenCV_DIR "F:/vcpkg_cenit/installed/x64-windows-release/share/opencv4")
find_package(OpenCV REQUIRED)
message(STATUS "OpenCV_FOUND: ${OpenCV_FOUND}")
message(STATUS "OpenCV_VERSION: ${OpenCV_VERSION}")
message(STATUS "OpenCV_INCLUDE_DIRS: ${OpenCV_INCLUDE_DIRS}")
message(STATUS "OpenCV_LIBS: ${OpenCV_LIBS}")
add_executable(test_ocv opencv_test.cpp)
target_include_directories(test_ocv PRIVATE ${OpenCV_INCLUDE_DIRS})
target_link_libraries(test_ocv PRIVATE ${OpenCV_LIBS})
install(TARGETS test_ocv DESTINATION ${CMAKE_CURRENT_LIST_DIR})

#find_package(CUDNN)
#find_package(BLAS)
#find_package(OpenBLAS)
#find_package(LAPACK)
#find_package(LibLZMA REQUIRED NO_MODULE)
#find_package(TIFF)
#find_package(LAPACK CONFIG REQUIRED)
#find_package(FFMPEG)
#find_package(OpenMP REQUIRED)
#find_package(OpenEXR)
#find_package(CUDA)
#set(protobuf_MODULE_COMPATIBLE ON CACHE BOOL "Enable compatible protobuf symbols")
#find_package(protobuf)
#set(OPENSSL_USE_STATIC_LIBS TRUE)
#find_package(OpenSSL REQUIRED)
#find_package(poly2tri REQUIRED)
#find_package(CXSDK)
#find_package(VTK 9 NAMES vtk COMPONENTS FiltersExtraction FiltersSources FiltersTexture IOExport IOGeometry IOPLY InteractionStyle RenderingCore RenderingLOD RenderingOpenGL2 NO_MODULE REQUIRED)
#find_package(GOSDK REQUIRED)

#message(STATUS "ENV{CUDACXX}: $ENV{CUDACXX}")

#find_path(BLAS_INCLUDE_DIR cblas.h)
#message(STATUS "BLAS_INCLUDE_DIR: ${BLAS_INCLUDE_DIR}")
#message(STATUS "BLAS_LIBRARIES: ${BLAS_LIBRARIES}")

#find_package(GIF)
#message(STATUS "GIF_INCLUDE_DIR: ${GIF_INCLUDE_DIR}")
#message(STATUS "GIF_LIBRARIES: ${GIF_LIBRARIES}")

#message(STATUS "CLAPACK_FOUND: ${CLAPACK_FOUND}")
#message(STATUS "CLAPACK_VERSION: ${CLAPACK_VERSION}")
#message(STATUS "CLAPACK_LIBRARY: ${CLAPACK_LIBRARY}")
#message(STATUS "LAPACK_LIBRARY: ${LAPACK_LIBRARY}")
#message(STATUS "LAPACK_LIBRARIES: ${LAPACK_LIBRARIES}")
#message(STATUS "CLAPACK_INCLUDE_DIR: ${CLAPACK_INCLUDE_DIR}")

#message(STATUS "LibLZMA_FOUND: ${LibLZMA_FOUND}")
#message(STATUS "LibLZMA_LIBRARIES: ${LibLZMA_LIBRARIES}")

#message(STATUS "Protobuf_LIBRARIES: ${Protobuf_LIBRARIES}")
#message(STATUS "PROTOBUF_LIBRARIES: ${PROTOBUF_LIBRARIES}")
#message(STATUS "protobuf_LIBRARIES: ${protobuf_LIBRARIES}")

#message(STATUS "FFMPEG_INCLUDE_DIRS : ${FFMPEG_INCLUDE_DIRS}")
#message(STATUS "FFMPEG_libavformat_LIBRARY : FOUND: ${FFMPEG_libavformat_FOUND} - ${FFMPEG_libavformat_LIBRARY}")
#message(STATUS "FFMPEG_libavdevice_LIBRARY : FOUND: ${FFMPEG_libavdevice_FOUND} - ${FFMPEG_libavdevice_LIBRARY}")
#message(STATUS "FFMPEG_libavcodec_LIBRARY : FOUND: ${FFMPEG_libavcodec_FOUND} - ${FFMPEG_libavcodec_LIBRARY}")
#message(STATUS "FFMPEG_libswresample_LIBRARY : FOUND: ${FFMPEG_libswresample_FOUND} - ${FFMPEG_libswresample_LIBRARY}")
#message(STATUS "FFMPEG_libavresample_LIBRARY : FOUND: ${FFMPEG_libavresample_FOUND} - ${FFMPEG_libavresample_LIBRARY}")
#message(STATUS "FFMPEG_libavutil_LIBRARY : FOUND: ${FFMPEG_libavutil_FOUND} - ${FFMPEG_libavutil_LIBRARY}")
#message(STATUS "FFMPEG_libswscale_LIBRARY : FOUND: ${FFMPEG_libswscale_FOUND} - ${FFMPEG_libswscale_LIBRARY}")
#message(STATUS "FFMPEG_PLATFORM_DEPENDENT_LIBS : ${FFMPEG_PLATFORM_DEPENDENT_LIBS}")
#message(STATUS "FFMPEG_LIBRARIES : ${FFMPEG_LIBRARIES}")

#message(STATUS "OPENEXR_VERSION : ${OPENEXR_VERSION}")
#message(STATUS "OPENEXR_LIBRARIES : ${OPENEXR_LIBRARIES}")
#message(STATUS "OPENEXR_INCLUDE_DIRS : ${OPENEXR_INCLUDE_DIRS}")
#add_executable(openexr_test openexr_test.cpp)
#target_link_libraries(openexr_test ${OPENEXR_LIBRARIES})

#add_executable(prova_blas call_blas.c)
#target_include_directories(prova_blas PRIVATE ${BLAS_INCLUDE_DIR})
#target_link_libraries(prova_blas BLAS::BLAS)

#add_executable(prova_openblas call_blas.c)
#target_link_libraries(prova_openblas OpenBLAS::OpenBLAS)

#add_executable(prova_lapack call_lapack.cpp)
#target_link_libraries(prova_lapack ${LAPACK_LIBRARIES})
#target_link_libraries(prova_lapack clapack::clapack)

#add_executable(prova_ffmpeg ffmpeg_test.cpp)
#target_include_directories(prova_ffmpeg PRIVATE ${FFMPEG_INCLUDE_DIRS})
#target_link_libraries(prova_ffmpeg PRIVATE ${FFMPEG_LIBRARIES})

#try_compile(__VALID_FFMPEG
#  "${CMAKE_CURRENT_BINARY_DIR}"
#  "${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg_test.cpp"
#  CMAKE_FLAGS "-DINCLUDE_DIRECTORIES:STRING=${FFMPEG_INCLUDE_DIRS}"
#              "-DLINK_LIBRARIES:STRING=${FFMPEG_LIBRARIES}"
#  OUTPUT_VARIABLE TRY_OUT
#)
#if(NOT __VALID_FFMPEG)
#  message(STATUS "WARNING: Can't build ffmpeg test code")
#endif()

#add_executable(prova_openmp openmp_test.cpp)
#target_link_libraries(prova_openmp PRIVATE OpenMP::OpenMP_CXX)

#add_executable(prova_cuda cuda_test.cpp)
#target_include_directories(prova_cuda PRIVATE ${CUDA_INCLUDE_DIRS})

#add_executable(prova_ssl ssl_test.cpp)
#target_link_libraries(prova_ssl PRIVATE OpenSSL::SSL OpenSSL::Crypto)

#add_executable(prova_polytri polytri.test.cpp)
#target_link_libraries(prova_polytri PRIVATE poly2tri::poly2tri)

#add_executable(prova_cxsdk cxsdk_test.cpp)
#target_link_libraries(prova_cxsdk PRIVATE AT::CxBaseLib)

#add_executable(vtk_test vtk_test.cpp)
#target_include_directories(vtk_test PRIVATE ${VTK_INCLUDE_DIRS})
#target_link_libraries(vtk_test PRIVATE ${VTK_LIBRARIES})

#add_executable(prova_gocator gocator_test.cpp)
#target_link_libraries(prova_gocator PRIVATE GO::SDK GO::KAPI)
