# $ROOT/external/libevent/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
project(LibeventExternalProject LANGUAGES C)

include(ExternalProject)

ExternalProject_Add(libevent_externalproject
        GIT_REPOSITORY https://github.com/libevent/libevent.git
        GIT_TAG        master
        GIT_SHALLOW    ON

        SOURCE_DIR     ${CMAKE_SOURCE_DIR}/external/libevent/source
        BINARY_DIR     ${CMAKE_SOURCE_DIR}/external/libevent/bin
        INSTALL_DIR    ${CMAKE_SOURCE_DIR}/external/libevent/install

        CONFIGURE_COMMAND
        ${CMAKE_COMMAND}
        -DBUILD_SHARED_LIBS=OFF
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/libevent/install
        -DZLIB_INCLUDE_DIR=${CMAKE_SOURCE_DIR}/external/zlib/install/include
        -DZLIB_LIBRARY=${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.a
        ../source

        BUILD_COMMAND   ${CMAKE_COMMAND} --build .
        INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix=${CMAKE_SOURCE_DIR}/external/libevent/install
        TEST_COMMAND    ""

        USES_TERMINAL_DOWNLOAD TRUE
        USES_TERMINAL_UPDATE   TRUE
        USES_TERMINAL_PATCH    TRUE
        USES_TERMINAL_CONFIGURE TRUE
        USES_TERMINAL_BUILD     TRUE
        USES_TERMINAL_INSTALL   TRUE
        USES_TERMINAL_TEST      TRUE

        # Optional but helpful for dependency tracking
        BUILD_BYPRODUCTS
        ${CMAKE_SOURCE_DIR}/external/libevent/install/lib/libevent.a

        # If you build zlib as an ExternalProject too, keep this:
        DEPENDS zlib_externalproject
)

# Use ExternalProject_Get_Property just for INSTALL_DIR
ExternalProject_Get_Property(libevent_externalproject INSTALL_DIR)

# Ensure headers dir exists for IDEs before first build
file(MAKE_DIRECTORY ${INSTALL_DIR}/include)

# Modern imported STATIC target for consumers
add_library(Libevent::event STATIC IMPORTED GLOBAL)
set_target_properties(Libevent::event PROPERTIES
        IMPORTED_LOCATION             ${INSTALL_DIR}/lib/libevent.a
        INTERFACE_INCLUDE_DIRECTORIES ${INSTALL_DIR}/include
)
add_dependencies(Libevent::event libevent_externalproject)