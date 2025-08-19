# $ROOT/external/libuv/Findlsquic.cmake
cmake_minimum_required(VERSION 3.24)
include(ExternalProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

ExternalProject_Add(lsquic_externalproject
        GIT_REPOSITORY https://github.com/litespeedtech/lsquic.git
        GIT_TAG v4.3.0
        GIT_SHALLOW ON
        SOURCE_DIR  ${CMAKE_SOURCE_DIR}/external/lsquic/source
        BINARY_DIR  ${CMAKE_SOURCE_DIR}/external/lsquic/bin
        CONFIGURE_COMMAND BORINGSSL=${CMAKE_SOURCE_DIR}/external/boringssl/source
        ${CMAKE_COMMAND}
        -DBUILD_SHARED_LIBS=1
        -DBORINGSSL_DIR=${CMAKE_SOURCE_DIR}/external/boringssl/source
        -DBORINGSSL_INCLUDE=${CMAKE_SOURCE_DIR}/external/boringssl/source/include
        -DBORINGSSL_LIB_ssl=${CMAKE_SOURCE_DIR}/external/boringssl/bin/libssl.so
        -DBORINGSSL_LIB_crypto=${CMAKE_SOURCE_DIR}/external/boringssl/bin/libcrypto.so
        -DZLIB_INCLUDE_DIR=${CMAKE_SOURCE_DIR}/external/zlib/source
        -DZLIB_LIB=${CMAKE_SOURCE_DIR}/external/zlib/bin/libz.so
#        -DEVENT_INCLUDE_DIR=${LIBEVENT_INCLUDE_DIR};
#        -DEVENT_LIB=${CMAKE_SOURCE_DIR}/external/libevent/bin/lib/libevent.so
        -DCMAKE_BUILD_TYPE=Release
        ../source
        CMAKE_ARGS -DCMAKE_PROJECT_lsquic_externalproject_INCLUDE=${CMAKE_SOURCE_DIR}/external/lsquic/cmake/fix_lsquic_externalproject.cmake
        BUILD_COMMAND ${CMAKE_COMMAND} --build ../bin
        INSTALL_COMMAND ""
        TEST_COMMAND ""
        BUILD_BYPRODUCTS ${CMAKE_SOURCE_DIR}/external/lsquic/bin/lsquic.so
        USES_TERMINAL_DOWNLOAD true
        USES_TERMINAL_UPDATE true
        USES_TERMINAL_PATCH true
        USES_TERMINAL_CONFIGURE true
        USES_TERMINAL_BUILD true
        USES_TERMINAL_INSTALL true
        USES_TERMINAL_TEST true
        DEPENDS zlib_externalproject
        DEPENDS boringssl_externalproject
        DEPENDS libevent_externalproject
)
ExternalProject_Get_Property(lsquic_externalproject SOURCE_DIR)
ExternalProject_Get_Property(lsquic_externalproject BINARY_DIR)
#set options
set(WITH_BORINGSSL ${CMAKE_SOURCE_DIR}/external/boringssl/bin CACHE INTERNAL "path to boringssl" FORCE)
set(LSQUIC_INCLUDE_DIR ${SOURCE_DIR}/include PARENT_SCOPE)
add_library(lsquic INTERFACE)
set_target_properties (lsquic PROPERTIES
        IMPORTED_LOCATION ${BINARY_DIR}/lsquic.so
        INTERFACE_INCLUDE_DIRECTORIES ${SOURCE_DIR}/include
)
target_include_directories(lsquic INTERFACE ${ZLIB_INCLUDE_DIR} ${LIBEVENT_INCLUDE_DIR})