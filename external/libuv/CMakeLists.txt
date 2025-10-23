# $ROOT/external/libuv/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
project(LibuvExternalProject LANGUAGES C CXX)

include(ExternalProject)

ExternalProject_Add(libuv_externalproject
        GIT_REPOSITORY https://github.com/libuv/libuv
        GIT_TAG        v1.x
        GIT_SHALLOW    ON

        SOURCE_DIR     ${CMAKE_SOURCE_DIR}/external/libuv/source
        BINARY_DIR     ${CMAKE_SOURCE_DIR}/external/libuv/bin
        INSTALL_DIR    ${CMAKE_SOURCE_DIR}/external/libuv/install

        CONFIGURE_COMMAND
        ${CMAKE_COMMAND}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/libuv/install
        ../source

        BUILD_COMMAND
        ${CMAKE_COMMAND} --build . --target uv uv_a

        INSTALL_COMMAND
        ${CMAKE_COMMAND} --install . --prefix=${CMAKE_SOURCE_DIR}/external/libuv/install

        TEST_COMMAND ""
        USES_TERMINAL_DOWNLOAD TRUE
        USES_TERMINAL_UPDATE   TRUE
        USES_TERMINAL_PATCH    TRUE
        USES_TERMINAL_CONFIGURE TRUE
        USES_TERMINAL_BUILD     TRUE
        USES_TERMINAL_INSTALL   TRUE
        USES_TERMINAL_TEST      TRUE

        BUILD_BYPRODUCTS
        ${CMAKE_SOURCE_DIR}/external/libuv/install/lib/libuv.so
        ${CMAKE_SOURCE_DIR}/external/libuv/install/lib/libuv.a
)

# Ensure include dir exists to avoid configure-time warnings
file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/external/libuv/install/include)

# Imported SHARED target
add_library(Libuv::uv SHARED IMPORTED GLOBAL)
set_target_properties(Libuv::uv PROPERTIES
        IMPORTED_LOCATION             ${CMAKE_SOURCE_DIR}/external/libuv/install/lib/libuv.so
        INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_SOURCE_DIR}/external/libuv/install/include
)
add_dependencies(Libuv::uv libuv_externalproject)

# Imported STATIC target
find_package(Threads REQUIRED)
add_library(Libuv::uv_a STATIC IMPORTED GLOBAL)
set_target_properties(Libuv::uv_a PROPERTIES
        IMPORTED_LOCATION             ${CMAKE_SOURCE_DIR}/external/libuv/install/lib/libuv.a
        INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_SOURCE_DIR}/external/libuv/install/include
        INTERFACE_LINK_LIBRARIES      "Threads::Threads;dl"
)
# libuv static needs pthread and dl on Linux
target_link_libraries(Libuv::uv_a INTERFACE Threads::Threads dl)
add_dependencies(Libuv::uv_a libuv_externalproject)