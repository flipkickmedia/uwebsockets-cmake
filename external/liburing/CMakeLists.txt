cmake_minimum_required(VERSION 3.24)
project(LiburingExternalProject LANGUAGES C CXX)

include(ExternalProject)
include(ProcessorCount)
ProcessorCount(NPROC)
if (NOT NPROC OR NPROC EQUAL 0)
    set(NPROC 1)
endif()

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
set(LIBURING_ROOT     ${CMAKE_SOURCE_DIR}/external/liburing)
set(LIBURING_SOURCE   ${LIBURING_ROOT}/source)
set(LIBURING_BUILD    ${LIBURING_ROOT}/build)
set(LIBURING_INSTALL  ${LIBURING_ROOT}/install)
set(LIBURING_SCRIPTS  ${LIBURING_ROOT}/scripts)
file(MAKE_DIRECTORY ${LIBURING_SCRIPTS})

set(LIBURING_REPO https://github.com/axboe/liburing.git)
set(LIBURING_TAG  liburing-2.11)

# A file that stores the last successfully built commit/tag
set(LIBURING_VERSION_FILE ${LIBURING_BUILD}/last_built_version.txt)

# ---------------------------------------------------------------------------
# Helper: Bash-safe variable expansion
# ---------------------------------------------------------------------------
string(REPLACE ";" " " NPROC_STR "${NPROC}")

# ---------------------------------------------------------------------------
# configure.sh
# ---------------------------------------------------------------------------
file(WRITE ${LIBURING_SCRIPTS}/configure.sh
        "#!/usr/bin/env bash
set -e

STAMP_FILE=\"${LIBURING_BUILD}/configured.stamp\"
VERSION_FILE=\"${LIBURING_VERSION_FILE}\"
CURRENT_VERSION=\"${LIBURING_TAG}\"

# If the recorded version differs from the current one, force reconfigure
if [ -f \"$VERSION_FILE\" ]; then
  PREV_VERSION=\$(cat \"$VERSION_FILE\")
else
  PREV_VERSION=\"\"
fi

if [ -f \"$STAMP_FILE\" ] && [ \"\$PREV_VERSION\" == \"\$CURRENT_VERSION\" ]; then
  echo \"[liburing] Already configured for version \$CURRENT_VERSION, skipping.\"
  exit 0
fi

echo \"[liburing] Configuring liburing (\$CURRENT_VERSION)...\"
cd \"${LIBURING_SOURCE}\"
./configure --prefix=\"${LIBURING_INSTALL}\"

echo \"\$CURRENT_VERSION\" > \"$VERSION_FILE\"
touch \"$STAMP_FILE\"
")

# ---------------------------------------------------------------------------
# build.sh
# ---------------------------------------------------------------------------
file(WRITE ${LIBURING_SCRIPTS}/build.sh
        "#!/usr/bin/env bash
set -e
STAMP_FILE=\"${LIBURING_BUILD}/built.stamp\"

if [ -f \"$STAMP_FILE\" ]; then
  echo \"[liburing] Already built, skipping.\"
  exit 0
fi

echo \"[liburing] Building liburing...\"
cd \"${LIBURING_SOURCE}\"
make -j${NPROC_STR}

touch \"$STAMP_FILE\"
")

# ---------------------------------------------------------------------------
# install.sh
# ---------------------------------------------------------------------------
file(WRITE ${LIBURING_SCRIPTS}/install.sh
        "#!/usr/bin/env bash
set -e
STAMP_FILE=\"${LIBURING_BUILD}/installed.stamp\"

if [ -f \"$STAMP_FILE\" ]; then
  echo \"[liburing] Already installed, skipping.\"
  exit 0
fi

echo \"[liburing] Installing liburing...\"
cd \"${LIBURING_SOURCE}\"
make install

touch \"$STAMP_FILE\"
")

# Make scripts executable
file(GLOB SCRIPT_FILES ${LIBURING_SCRIPTS}/*.sh)
foreach(script ${SCRIPT_FILES})
    file(COPY ${script} DESTINATION ${LIBURING_SCRIPTS}
            FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
endforeach()

# ---------------------------------------------------------------------------
# ExternalProject_Add
# ---------------------------------------------------------------------------
ExternalProject_Add(liburing_externalproject
        GIT_REPOSITORY ${LIBURING_REPO}
        GIT_TAG        ${LIBURING_TAG}
        GIT_SHALLOW    ON

        SOURCE_DIR     ${LIBURING_SOURCE}
        BINARY_DIR     ${LIBURING_BUILD}
        INSTALL_DIR    ${LIBURING_INSTALL}

        CONFIGURE_COMMAND bash ${LIBURING_SCRIPTS}/configure.sh
        BUILD_COMMAND     bash ${LIBURING_SCRIPTS}/build.sh
        INSTALL_COMMAND   bash ${LIBURING_SCRIPTS}/install.sh

        BUILD_BYPRODUCTS
        ${LIBURING_INSTALL}/lib/liburing.a
        ${LIBURING_BUILD}/installed.stamp

        USES_TERMINAL_DOWNLOAD YES
        USES_TERMINAL_CONFIGURE YES
        USES_TERMINAL_BUILD YES
        USES_TERMINAL_INSTALL YES
)

# ---------------------------------------------------------------------------
# CMake interface library
# ---------------------------------------------------------------------------
add_library(liburing INTERFACE)
target_include_directories(liburing INTERFACE ${LIBURING_INSTALL}/include)
target_link_libraries(liburing INTERFACE ${LIBURING_INSTALL}/lib/liburing.a)
add_dependencies(liburing liburing_externalproject)