# $ROOT/external/libevent/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)

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
        -S ${CMAKE_SOURCE_DIR}/external/libevent/source
        -B ${CMAKE_SOURCE_DIR}/external/libevent/bin
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/libevent/install
        # libevent's CMake supports Zlib via these cache vars:
        -DZLIB_INCLUDE_DIR=${CMAKE_SOURCE_DIR}/external/zlib/source
        -DZLIB_LIBRARY=${CMAKE_SOURCE_DIR}/external/zlib/bin/libz.so
        BUILD_COMMAND   ${CMAKE_COMMAND} --build ${CMAKE_SOURCE_DIR}/external/libevent/bin
        INSTALL_COMMAND ${CMAKE_COMMAND} --install ${CMAKE_SOURCE_DIR}/external/libevent/bin --prefix=${CMAKE_SOURCE_DIR}/external/libevent/install
        TEST_COMMAND    ""
        USES_TERMINAL_DOWNLOAD TRUE
        USES_TERMINAL_UPDATE   TRUE
        USES_TERMINAL_PATCH    TRUE
        USES_TERMINAL_CONFIGURE TRUE
        USES_TERMINAL_BUILD     TRUE
        USES_TERMINAL_INSTALL   TRUE
        USES_TERMINAL_TEST      TRUE
        DEPENDS zlib_externalproject
        BUILD_BYPRODUCTS
        ${CMAKE_SOURCE_DIR}/external/libevent/install/lib/libevent.a
)

# Pull the install dir from the ExternalProject (no hand-rolled vars exported)
ExternalProject_Get_Property(libevent_externalproject INSTALL_DIR)

# Provide a proper imported target that dependents can link against.
# This target carries include dirs and the archive path via properties.
add_library(Libevent::event STATIC IMPORTED GLOBAL)
set_target_properties(Libevent::event PROPERTIES
        IMPORTED_LOCATION             "${INSTALL_DIR}/lib/libevent.a"
        INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
)
add_dependencies(Libevent::event libevent_externalproject)