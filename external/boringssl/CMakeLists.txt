# $ROOT/external/boringssl/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)

include(ExternalProject)

ExternalProject_Add(boringssl_externalproject
        GIT_REPOSITORY https://github.com/google/boringssl
        GIT_TAG        0.20250807.0
        GIT_SHALLOW    ON

        SOURCE_DIR     ${CMAKE_SOURCE_DIR}/external/boringssl/source
        BINARY_DIR     ${CMAKE_SOURCE_DIR}/external/boringssl/bin
        INSTALL_DIR    ${CMAKE_SOURCE_DIR}/external/boringssl/install

        CONFIGURE_COMMAND
        ${CMAKE_COMMAND}
        -DCMAKE_CXX_STANDARD=17
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/boringssl/install
        ../source

        BUILD_COMMAND
        ${CMAKE_COMMAND} --build . --target ssl crypto

        # Manual "install": copy libs and public headers to INSTALL_DIR - cmake --install borks because we only compiled
        # specific targets
        INSTALL_COMMAND
        ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/lib
        COMMAND ${CMAKE_COMMAND} -E make_directory <INSTALL_DIR>/include
        COMMAND ${CMAKE_COMMAND} -E copy          <BINARY_DIR>/libssl.a     <INSTALL_DIR>/lib/libssl.a
        COMMAND ${CMAKE_COMMAND} -E copy          <BINARY_DIR>/libcrypto.a <INSTALL_DIR>/lib/libcrypto.a
        COMMAND ${CMAKE_COMMAND} -E copy_directory <SOURCE_DIR>/include          <INSTALL_DIR>/include


        TEST_COMMAND ""

        BUILD_BYPRODUCTS
        ${CMAKE_SOURCE_DIR}/external/boringssl/install/lib/libssl.a
        ${CMAKE_SOURCE_DIR}/external/boringssl/install/lib/libcrypto.a

        USES_TERMINAL_DOWNLOAD  true
        USES_TERMINAL_UPDATE    true
        USES_TERMINAL_PATCH     true
        USES_TERMINAL_CONFIGURE true
        USES_TERMINAL_BUILD     true
        USES_TERMINAL_INSTALL   true
        USES_TERMINAL_TEST      true
)

# Get the ExternalProject's computed install dir
ExternalProject_Get_Property(boringssl_externalproject INSTALL_DIR)
file(MAKE_DIRECTORY ${INSTALL_DIR}/include)
# Imported targets for consumers
find_package(Threads REQUIRED)

add_library(BoringSSL::crypto STATIC IMPORTED GLOBAL)
set_target_properties(BoringSSL::crypto PROPERTIES
        IMPORTED_LOCATION             "${INSTALL_DIR}/lib/libcrypto.a"
        INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
)
add_dependencies(BoringSSL::crypto boringssl_externalproject)
target_link_libraries(BoringSSL::crypto INTERFACE Threads::Threads dl)

add_library(BoringSSL::ssl STATIC IMPORTED GLOBAL)
set_target_properties(BoringSSL::ssl PROPERTIES
        IMPORTED_LOCATION             "${INSTALL_DIR}/lib/libssl.a"
        INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
)
add_dependencies(BoringSSL::ssl boringssl_externalproject)
# (No link to BoringSSL::crypto; consumers link both explicitly)