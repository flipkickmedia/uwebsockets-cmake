# $ROOT/external/libevent/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
include(ExternalProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

ExternalProject_Add(liburing_externalproject
        GIT_REPOSITORY https://github.com/axboe/liburing.git
        GIT_TAG liburing-2.8
        GIT_SHALLOW ON
        SOURCE_DIR  ${CMAKE_SOURCE_DIR}/external/liburing/source
        BINARY_DIR ${CMAKE_SOURCE_DIR}/external/liburing/bin
        CONFIGURE_COMMAND cd ../source ; configure
        BUILD_COMMAND cd ../source ; make -j\$(nproc)
        INSTALL_COMMAND ""
        TEST_COMMAND ""
        USES_TERMINAL_DOWNLOAD true
        USES_TERMINAL_UPDATE true
        USES_TERMINAL_PATCH true
        USES_TERMINAL_CONFIGURE true
        USES_TERMINAL_BUILD true
        USES_TERMINAL_INSTALL true
        USES_TERMINAL_TEST true
)
ExternalProject_Get_Property(liburing_externalproject SOURCE_DIR)
ExternalProject_Get_Property(liburing_externalproject BINARY_DIR)
set(LIBURING_INCLUDE_DIR  ${SOURCE_DIR}/src/include PARENT_SCOPE)
set(LIBURING_LIBRARY  ${BINARY_DIR}/liburing.so PARENT_SCOPE)
add_library(liburing INTERFACE)
target_include_directories(liburing INTERFACE ${SOURCE_DIR}/src/include)
target_link_libraries(liburing INTERFACE ${SOURCE_DIR}/build/liburing.so)
