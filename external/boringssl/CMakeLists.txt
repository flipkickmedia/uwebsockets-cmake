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
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ../source -DBUILD_SHARED_LIBS=1 -DCMAKE_BUILD_TYPE=Release
        BUILD_COMMAND ${CMAKE_COMMAND} --build . --target ssl crypto
        INSTALL_COMMAND ""
        TEST_COMMAND ""
        BUILD_BYPRODUCTS ${CMAKE_SOURCE_DIR}/external/boringssl/bin/libssl.so ${CMAKE_SOURCE_DIR}/external/boringssl/bin/libcrypto.so
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
set(BORINGSSL_INCLUDE  ${SOURCE_DIR}/include PARENT_SCOPE)
set(BORINGSSL_INCLUDE_DIR  ${SOURCE_DIR}/include PARENT_SCOPE)
set(BORINGSSL_LIB_SSL  ${BINARY_DIR}/libssl.so PARENT_SCOPE)
set(BORINGSSL_LIB_CRYPTO  ${BINARY_DIR}/libcrypto.so PARENT_SCOPE)
add_library(boringssl_ssl SHARED IMPORTED)
add_library(boringssl_crypto SHARED IMPORTED)
target_include_directories(boringssl_ssl INTERFACE ${SOURCE_DIR}/src)
target_include_directories(boringssl_crypto INTERFACE ${SOURCE_DIR}/src)
target_link_libraries(boringssl_ssl INTERFACE ${BINARY_DIR}/libssl.so)
target_link_libraries(boringssl_crypto INTERFACE ${BINARY_DIR}/libcrypto.so)
#set_target_properties(boringssl INTERFACE ${SOURCE_DIR}/build/libcrypto.a ${SOURCE_DIR}/build/libssl.a)
