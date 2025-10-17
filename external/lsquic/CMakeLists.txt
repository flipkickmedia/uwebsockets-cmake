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
        INSTALL_DIR ${CMAKE_SOURCE_DIR}/external/lsquic/install
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
        -DBUILD_SHARED_LIBS=1
        -DCMAKE_CXX_STANDARD=17
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/lsquic/install
        -DBORINGSSL_DIR=${CMAKE_SOURCE_DIR}/external/boringssl/install
        -DBORINGSSL_INCLUDE=${CMAKE_SOURCE_DIR}/external/boringssl/install/include
        -DBORINGSSL_LIB_ssl=${CMAKE_SOURCE_DIR}/external/boringssl/install/lib/libssl.a
        -DBORINGSSL_LIB_crypto=${CMAKE_SOURCE_DIR}/external/boringssl/install/lib/libcrypto.a
        -DZLIB_INCLUDE_DIR=${CMAKE_SOURCE_DIR}/external/zlib/install/include
        -DZLIB_LIB=${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.a
        -DEVENT_LIB=${CMAKE_SOURCE_DIR}/external/libevent/bin/lib/libevent.so
        ../source
        #CMAKE_ARGS -DCMAKE_PROJECT_lsquic_externalproject_INCLUDE=${CMAKE_SOURCE_DIR}/external/lsquic/cmake/fix_lsquic_externalproject.cmake
        BUILD_COMMAND ${CMAKE_COMMAND} --build ../bin --target lsquic
        INSTALL_COMMAND ${CMAKE_COMMAND} --build ../bin --target install
        TEST_COMMAND ""
        BUILD_BYPRODUCTS ${CMAKE_SOURCE_DIR}/external/lsquic/install/lib/lsquic.so
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
ExternalProject_Get_Property(lsquic_externalproject INSTALL_DIR)
#set options
set(WITH_BORINGSSL ${CMAKE_SOURCE_DIR}/external/boringssl/bin CACHE INTERNAL "path to boringssl" FORCE)
set(LSQUIC_INCLUDE_DIR ${INSTALL_DIR}/include PARENT_SCOPE)
set(LSQUIC_LIBRARY ${INSTALL_DIR}/lib/lsquic.so PARENT_SCOPE)
add_library(lsquic INTERFACE)
set_target_properties (lsquic PROPERTIES
        IMPORTED_LOCATION ${LSQUIC_LIBRARY}
        INTERFACE_INCLUDE_DIRECTORIES ${LSQUIC_INCLUDE_DIR}
)
target_include_directories(lsquic INTERFACE
        ${INSTALL_DIR}/include/lsquic
        ${ZLIB_INCLUDE_DIR}
        ${LIBEVENT_INCLUDE_DIR}
)
