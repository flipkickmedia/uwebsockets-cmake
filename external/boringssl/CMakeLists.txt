# $ROOT/external/boringssl/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
include(ExternalProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

ExternalProject_Add(boringssl_externalproject
        GIT_REPOSITORY https://github.com/google/boringssl
        GIT_TAG 0.20250807.0
        GIT_SHALLOW ON
        SOURCE_DIR  ${CMAKE_SOURCE_DIR}/external/boringssl/source
        BINARY_DIR ${CMAKE_SOURCE_DIR}/external/boringssl/bin
        INSTALL_DIR ${CMAKE_SOURCE_DIR}/external/boringssl/install
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
        -DCMAKE_CXX_STANDARD=17
        #-DBUILD_SHARED_LIBS=1
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/boringssl/install
        ../source
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --target ssl crypto
        INSTALL_COMMAND ${CMAKE_COMMAND} --build . --target install
        TEST_COMMAND ""
        BUILD_BYPRODUCTS ${CMAKE_SOURCE_DIR}/external/boringssl/install/lib/libssl.a
        BUILD_BYPRODUCTS ${CMAKE_SOURCE_DIR}/external/boringssl/install/lib/libcrypto.a
        USES_TERMINAL_DOWNLOAD true
        USES_TERMINAL_UPDATE true
        USES_TERMINAL_PATCH true
        USES_TERMINAL_CONFIGURE true
        USES_TERMINAL_BUILD true
        USES_TERMINAL_INSTALL true
        USES_TERMINAL_TEST true
)
ExternalProject_Get_Property(boringssl_externalproject SOURCE_DIR)
ExternalProject_Get_Property(boringssl_externalproject BINARY_DIR)
ExternalProject_Get_Property(boringssl_externalproject INSTALL_DIR)
set(BORINGSSL_INCLUDE  ${INSTALL_DIR}/include PARENT_SCOPE)
set(BORINGSSL_INCLUDE_DIR  ${INSTALL_DIR}/include PARENT_SCOPE)
set(BORINGSSL_LIB_SSL  ${INSTALL_DIR}/lib/libssl.a PARENT_SCOPE)
set(BORINGSSL_LIB_CRYPTO  ${INSTALL_DIR}/lib/libcrypto.a PARENT_SCOPE)

add_library(boringssl_ssl SHARED IMPORTED)
target_include_directories(boringssl_ssl INTERFACE ${INSTALL_DIR}/include)
target_link_libraries(boringssl_ssl INTERFACE ${INSTALL_DIR}/lib/libssl.a)

add_library(boringssl_crypto SHARED IMPORTED)
target_include_directories(boringssl_crypto INTERFACE ${INSTALL_DIR}/include/src)
target_link_libraries(boringssl_crypto INTERFACE ${INSTALL_DIR}/lib/libcrypto.so)
