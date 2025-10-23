# $ROOT/external/libevent/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
project(LibeventExternalProject LANGUAGES C)

include(ExternalProject)

# --- Paths used in both CMake and the script
set(_src_dir   ${CMAKE_SOURCE_DIR}/external/libevent/source)
set(_bin_dir   ${CMAKE_SOURCE_DIR}/external/libevent/bin)
set(_inst_dir  ${CMAKE_SOURCE_DIR}/external/libevent/install)
set(_scripts   ${CMAKE_SOURCE_DIR}/external/libevent/scripts)
file(MAKE_DIRECTORY ${_scripts})

# --- Write the standalone install script - we need this because the install process for libevent is broken
file(WRITE ${_scripts}/install_libevent.sh
        "#!/usr/bin/env bash
set -euo pipefail

echo \"[libevent] Manual install: copying lib and headers\"
mkdir -p \"${_inst_dir}/lib\" \"${_inst_dir}/include\"

# Copy the built static lib (prefer bin/lib/, fall back to bin/)
if [ -f \"${_bin_dir}/lib/libevent.a\" ]; then
  cp -f \"${_bin_dir}/lib/libevent.a\" \"${_inst_dir}/lib/\"
elif [ -f \"${_bin_dir}/libevent.a\" ]; then
  cp -f \"${_bin_dir}/libevent.a\" \"${_inst_dir}/lib/\"
else
  echo \"[libevent] ERROR: libevent.a not found in build output\" >&2
  exit 1
fi

# Copy public headers from source tree
cp -a \"${_src_dir}/include/.\" \"${_inst_dir}/include/\"

# Overlay generated event-config.h from build tree if present
if [ -f \"${_bin_dir}/include/event2/event-config.h\" ]; then
  mkdir -p \"${_inst_dir}/include/event2\"
  cp -f \"${_bin_dir}/include/event2/event-config.h\" \"${_inst_dir}/include/event2/event-config.h\"
else
  echo \"[libevent] WARNING: generated event-config.h not found; build may not be complete\" >&2
fi

echo \"[libevent] Manual install done -> ${_inst_dir}\"
")

# Make it executable
if (CMAKE_HOST_UNIX)
    file(CHMOD ${_scripts}/install_libevent.sh
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
            GROUP_READ GROUP_EXECUTE
            WORLD_READ WORLD_EXECUTE)
endif()


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
        -DLSQUIC_BIN=OFF
        -DLSQUIC_TESTS=OFF
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/libevent/install
        -DEVENT__DISABLE_OPENSSL=OFF
        -DOPENSSL_USE_STATIC_LIBS=TRUE
        # Point "OpenSSL" variables at BoringSSL install
        -DOPENSSL_INCLUDE_DIR=${CMAKE_SOURCE_DIR}/external/boringssl/install/include
        -DOPENSSL_SSL_LIBRARY=${CMAKE_SOURCE_DIR}/external/boringssl/install/lib/libssl.a
        -DOPENSSL_CRYPTO_LIBRARY=${CMAKE_SOURCE_DIR}/external/boringssl/install/lib/libcrypto.a
        -DZLIB_INCLUDE_DIR=${CMAKE_SOURCE_DIR}/external/zlib/install/include
        -DZLIB_LIBRARY=${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.a
        ../source

        BUILD_COMMAND   ${CMAKE_COMMAND} --build . --target event_static
        INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix=${CMAKE_SOURCE_DIR}/external/libevent/install
        #INSTALL_COMMAND bash ${_scripts}/install_libevent.sh

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