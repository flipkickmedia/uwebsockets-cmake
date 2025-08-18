# $ROOT/external/libevent/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
include(ExternalProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

ExternalProject_Add(libevent_externalproject
        GIT_REPOSITORY https://github.com/libevent/libevent.git
        GIT_TAG master
        GIT_SHALLOW ON
        SOURCE_DIR  ${CMAKE_SOURCE_DIR}/external/libevent/source
        BINARY_DIR ${CMAKE_SOURCE_DIR}/external/libevent/bin
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
        ../source
        -DZLIB_INCLUDE_DIR=${CMAKE_SOURCE_DIR}/external/zlib/source
        -DZLIB_LIBRARY=${CMAKE_SOURCE_DIR}/external/zlib/bin/libz.so
        -DCMAKE_BUILD_TYPE=Release
        BUILD_COMMAND ${CMAKE_COMMAND} --build .
        INSTALL_COMMAND ""
        TEST_COMMAND ""
        USES_TERMINAL_DOWNLOAD true
        USES_TERMINAL_UPDATE true
        USES_TERMINAL_PATCH true
        USES_TERMINAL_CONFIGURE true
        USES_TERMINAL_BUILD true
        USES_TERMINAL_INSTALL true
        USES_TERMINAL_TEST true
        DEPENDS zlib_externalproject
)
ExternalProject_Get_Property(libevent_externalproject SOURCE_DIR)
ExternalProject_Get_Property(libevent_externalproject BINARY_DIR)
set(LIBEVENT_INCLUDE_DIR "${SOURCE_DIR}/include;${BINARY_DIR}/include" PARENT_SCOPE)
set(LIBEVENT_LIBRARY  ${BINARY_DIR}/libevent.a PARENT_SCOPE)
add_library(libevent INTERFACE)
target_include_directories(libevent INTERFACE ${SOURCE_DIR}/include)
target_link_libraries(libevent INTERFACE ${BINARY_DIR}/libevent.pc)
