# $ROOT/external/liburing/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
project(LiburingExternalProject LANGUAGES C CXX)

include(ExternalProject)
include(ProcessorCount)
ProcessorCount(NPROC)
if (NOT NPROC OR NPROC EQUAL 0)
    set(NPROC 1)
endif()
string(REPLACE ";" " " NPROC_STR "${NPROC}")

# -----------------------------------------------------------------------------
# ExternalProject
# -----------------------------------------------------------------------------
ExternalProject_Add(liburing_externalproject
        GIT_REPOSITORY https://github.com/axboe/liburing.git
        GIT_TAG        master
        GIT_SHALLOW    ON

        SOURCE_DIR     ${CMAKE_SOURCE_DIR}/external/liburing/source
        BINARY_DIR     ${CMAKE_SOURCE_DIR}/external/liburing/build
        INSTALL_DIR    ${CMAKE_SOURCE_DIR}/external/liburing/install

        CONFIGURE_COMMAND bash ${CMAKE_SOURCE_DIR}/external/liburing/scripts/configure.sh
        BUILD_COMMAND     bash ${CMAKE_SOURCE_DIR}/external/liburing/scripts/build.sh
        INSTALL_COMMAND   bash ${CMAKE_SOURCE_DIR}/external/liburing/scripts/install.sh
        TEST_COMMAND      ""

        USES_TERMINAL_DOWNLOAD TRUE
        USES_TERMINAL_UPDATE   TRUE
        USES_TERMINAL_PATCH    TRUE
        USES_TERMINAL_CONFIGURE TRUE
        USES_TERMINAL_BUILD     TRUE
        USES_TERMINAL_INSTALL   TRUE
        USES_TERMINAL_TEST      TRUE

        BUILD_BYPRODUCTS
        ${CMAKE_SOURCE_DIR}/external/liburing/install/lib/liburing.a
        ${CMAKE_SOURCE_DIR}/external/liburing/build/installed.stamp
)

# -----------------------------------------------------------------------------
# Derive paths from ExternalProject properties
# -----------------------------------------------------------------------------
ExternalProject_Get_Property(liburing_externalproject INSTALL_DIR)
ExternalProject_Get_Property(liburing_externalproject SOURCE_DIR)
ExternalProject_Get_Property(liburing_externalproject BINARY_DIR)

get_filename_component(ROOT "${INSTALL_DIR}" DIRECTORY)
set(SCRIPTS "${ROOT}/scripts")
file(MAKE_DIRECTORY "${SCRIPTS}")

set(VERSION_FILE "${BINARY_DIR}/last_built_version.txt")

# -----------------------------------------------------------------------------
# Shell scripts (configure/build/install) – idempotent with stamps & version
# -----------------------------------------------------------------------------
file(WRITE "${SCRIPTS}/configure.sh" "
#!/usr/bin/env bash
set -euo pipefail

STAMP_FILE='${BINARY_DIR}/configured.stamp'
VERSION_FILE='${VERSION_FILE}'

echo '[liburing] Configuring...'
cd '${SOURCE_DIR}'

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  CURRENT_VERSION=\$(git rev-parse HEAD)
else
  CURRENT_VERSION='unknown'
fi

PREV_VERSION=''
if [ -f \"\$VERSION_FILE\" ]; then
  PREV_VERSION=\$(cat \"\$VERSION_FILE\")
fi

# Version change => invalidate later stages
if [ \"\$PREV_VERSION\" != \"\$CURRENT_VERSION\" ]; then
  rm -f '${BINARY_DIR}/built.stamp' '${BINARY_DIR}/installed.stamp'
fi

if [ -f \"\$STAMP_FILE\" ] && [ \"\$PREV_VERSION\" = \"\$CURRENT_VERSION\" ]; then
  echo \"[liburing] Already configured at \$CURRENT_VERSION, skipping.\"
  exit 0
fi

./configure --prefix='${INSTALL_DIR}'

echo \"\$CURRENT_VERSION\" > \"\$VERSION_FILE\"
touch \"\$STAMP_FILE\"
")

file(WRITE "${SCRIPTS}/build.sh" "
#!/usr/bin/env bash
set -euo pipefail
STAMP_FILE='${BINARY_DIR}/built.stamp'

if [ -f \"\$STAMP_FILE\" ]; then
  echo '[liburing] Already built, skipping.'
  exit 0
fi

echo '[liburing] Building...'
cd '${SOURCE_DIR}'
make -j${NPROC_STR}

touch \"\$STAMP_FILE\"
")

file(WRITE "${SCRIPTS}/install.sh" "
#!/usr/bin/env bash
set -euo pipefail
STAMP_FILE='${BINARY_DIR}/installed.stamp'

if [ -f \"\$STAMP_FILE\" ]; then
  echo '[liburing] Already installed, skipping.'
  exit 0
fi

echo '[liburing] Installing...'
cd '${SOURCE_DIR}'
make install

touch \"\$STAMP_FILE\"
")

# Make scripts executable
file(GLOB SCRIPT_FILES "${SCRIPTS}/*.sh")
if(SCRIPT_FILES)
    file(CHMOD ${SCRIPT_FILES}
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
            GROUP_READ GROUP_EXECUTE
            WORLD_READ WORLD_EXECUTE)
endif()

# -----------------------------------------------------------------------------
# Modern imported target for consumers
# -----------------------------------------------------------------------------
add_library(Liburing::uring STATIC IMPORTED GLOBAL)
# Avoid include-dir warning at configure time
file(MAKE_DIRECTORY "${INSTALL_DIR}/include")

set_target_properties(Liburing::uring PROPERTIES
        IMPORTED_LOCATION "${INSTALL_DIR}/lib/liburing.a"
)
target_include_directories(Liburing::uring INTERFACE "${INSTALL_DIR}/include")
add_dependencies(Liburing::uring liburing_externalproject)