cmake_minimum_required(VERSION 3.24)
project(LsquicExternalProject LANGUAGES C CXX)

include(ExternalProject)

ExternalProject_Add(lsquic_externalproject
        GIT_REPOSITORY https://github.com/litespeedtech/lsquic.git
        GIT_TAG        v4.3.0
        GIT_SHALLOW    ON

        SOURCE_DIR     ${CMAKE_SOURCE_DIR}/external/lsquic/source
        BINARY_DIR     ${CMAKE_SOURCE_DIR}/external/lsquic/bin
        INSTALL_DIR    ${CMAKE_SOURCE_DIR}/external/lsquic/install

        CONFIGURE_COMMAND
        ${CMAKE_COMMAND}
        -DBUILD_SHARED_LIBS=OFF
        -DCMAKE_CXX_STANDARD=17
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/lsquic/install
        # BoringSSL
        -DBORINGSSL_DIR=${CMAKE_SOURCE_DIR}/external/boringssl/install
        # Zlib (paths expected by lsquic)
        -DZLIB_INCLUDE_DIR=${CMAKE_SOURCE_DIR}/external/zlib/install/include
        -DZLIB_LIB=${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.a
        # libevent (static)
        -DEVENT_LIB=${CMAKE_SOURCE_DIR}/external/libevent/install/lib/libevent.a
        ../source

        BUILD_COMMAND   ${CMAKE_COMMAND} --build . --target lsquic
        INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix=${CMAKE_SOURCE_DIR}/external/lsquic/install
        TEST_COMMAND    ""

        USES_TERMINAL_DOWNLOAD TRUE
        USES_TERMINAL_UPDATE   TRUE
        USES_TERMINAL_PATCH    TRUE
        USES_TERMINAL_CONFIGURE TRUE
        USES_TERMINAL_BUILD     TRUE
        USES_TERMINAL_INSTALL   TRUE
        USES_TERMINAL_TEST      TRUE

        BUILD_BYPRODUCTS
        ${CMAKE_SOURCE_DIR}/external/lsquic/install/lib/liblsquic.a

        DEPENDS
        zlib_externalproject
        boringssl_externalproject
        libevent_externalproject
)

# Ensure include dir exists before first build
file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/external/lsquic/install/include)

# Export a modern imported STATIC target
add_library(Lsquic::lsquic STATIC IMPORTED GLOBAL)
set_target_properties(Lsquic::lsquic PROPERTIES
        IMPORTED_LOCATION ${CMAKE_SOURCE_DIR}/external/lsquic/install/lib/liblsquic.a
        INTERFACE_INCLUDE_DIRECTORIES
        "${CMAKE_SOURCE_DIR}/external/lsquic/install/include;${CMAKE_SOURCE_DIR}/external/lsquic/install/include/lsquic"
)
add_dependencies(Lsquic::lsquic lsquic_externalproject)

# Propagate deps to consumers
target_link_libraries(Lsquic::lsquic INTERFACE
        BoringSSL::ssl
        BoringSSL::crypto
        Libevent::event
        zlib
)