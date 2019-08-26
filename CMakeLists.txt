cmake_minimum_required(VERSION 2.8)
project(prova C CXX)

#find_package(BLAS)
#find_package(OpenBLAS)
#find_package(LAPACK)
#find_package(LibLZMA REQUIRED NO_MODULE)
#find_package(TIFF)
#find_package(LAPACK CONFIG REQUIRED)
find_package(FFMPEG)

#set(protobuf_MODULE_COMPATIBLE ON CACHE BOOL "Enable compatible protobuf symbols")
#find_package(protobuf)

#message(STATUS "CLAPACK_FOUND: ${CLAPACK_FOUND}")
#message(STATUS "CLAPACK_VERSION: ${CLAPACK_VERSION}")
#message(STATUS "CLAPACK_LIBRARY: ${CLAPACK_LIBRARY}")
#message(STATUS "LAPACK_LIBRARY: ${LAPACK_LIBRARY}")
#message(STATUS "CLAPACK_INCLUDE_DIR: ${CLAPACK_INCLUDE_DIR}")

#message(STATUS "LibLZMA_FOUND: ${LibLZMA_FOUND}")
#message(STATUS "LibLZMA_LIBRARIES: ${LibLZMA_LIBRARIES}")

#message(STATUS "Protobuf_LIBRARIES: ${Protobuf_LIBRARIES}")
#message(STATUS "PROTOBUF_LIBRARIES: ${PROTOBUF_LIBRARIES}")
#message(STATUS "protobuf_LIBRARIES: ${protobuf_LIBRARIES}")

message(STATUS "FFMPEG_INCLUDE_DIRS : ${FFMPEG_INCLUDE_DIRS}")
message(STATUS "FFMPEG_INCLUDE_DIR : ${FFMPEG_INCLUDE_DIR}")
message(STATUS "FFMPEG_libavformat_LIBRARY : FOUND: ${FFMPEG_libavformat_FOUND} - ${FFMPEG_libavformat_LIBRARY}")
message(STATUS "FFMPEG_libavdevice_LIBRARY : FOUND: ${FFMPEG_libavdevice_FOUND} - ${FFMPEG_libavdevice_LIBRARY}")
message(STATUS "FFMPEG_libavcodec_LIBRARY : FOUND: ${FFMPEG_libavcodec_FOUND} - ${FFMPEG_libavcodec_LIBRARY}")
message(STATUS "FFMPEG_libswresample_LIBRARY : FOUND: ${FFMPEG_libswresample_FOUND} - ${FFMPEG_libswresample_LIBRARY}")
message(STATUS "FFMPEG_libavutil_LIBRARY : FOUND: ${FFMPEG_libavutil_FOUND} - ${FFMPEG_libavutil_LIBRARY}")
message(STATUS "FFMPEG_libswscale_LIBRARY : FOUND: ${FFMPEG_libswscale_FOUND} - ${FFMPEG_libswscale_LIBRARY}")
message(STATUS "FFMPEG_PLATFORM_DEPENDENT_LIBS : ${FFMPEG_PLATFORM_DEPENDENT_LIBS}")
message(STATUS "FFMPEG_LIBRARIES : ${FFMPEG_LIBRARIES}")

#add_executable(prova_blas call_blas.c)
#target_include_directories(prova_blas PRIVATE ${BLAS_INCLUDE_DIRS})
#target_link_libraries(prova_blas ${BLAS_LIBRARIES})
#target_link_libraries(prova_blas OpenBLAS::OpenBLAS)

#add_executable(prova_lapack call_lapack.cpp)
#target_link_libraries(prova_lapack ${LAPACK_LIBRARIES})
#target_link_libraries(prova_lapack clapack::clapack)

#add_executable(prova_ffmpeg ffmpeg_test.cpp)
#target_link_libraries(prova_ffmpeg ${FFMPEG_LIBRARIES})

add_executable(VideoLoop opencv.cpp)
target_link_libraries(VideoLoop PRIVATE ${OpenCV_LIBS})
