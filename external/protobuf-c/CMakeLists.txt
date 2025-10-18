cmake_minimum_required(VERSION 3.24)
project(ProtobufCExternal LANGUAGES C CXX)

include(ExternalProject)
include(ProcessorCount)
ProcessorCount(NPROC)
if(NOT NPROC OR NPROC EQUAL 0)
    set(NPROC 1)
endif()

# ---------------------------------------------------------------------------
# Paths and settings
# ---------------------------------------------------------------------------
set(PROTOBUFC_REPO  https://github.com/protobuf-c/protobuf-c.git)
set(PROTOBUFC_TAG   v1.5.2)

set(PROTOBUFC_ROOT     ${CMAKE_SOURCE_DIR}/external/protobuf-c)
set(PROTOBUFC_SOURCE   ${PROTOBUFC_ROOT}/source)
set(PROTOBUFC_BUILD    ${PROTOBUFC_ROOT}/bin)
set(PROTOBUFC_INSTALL  ${PROTOBUFC_ROOT}/install)
set(PROTOBUFC_SCRIPTS  ${PROTOBUFC_ROOT}/scripts)
set(PROTOBUFC_VERSION_FILE ${PROTOBUFC_BUILD}/last_built_version.txt)
file(MAKE_DIRECTORY ${PROTOBUFC_SCRIPTS})

string(REPLACE ";" " " NPROC_STR "${NPROC}")

# ---------------------------------------------------------------------------
# configure.sh
# ---------------------------------------------------------------------------
file(WRITE ${PROTOBUFC_SCRIPTS}/configure.sh
        "#!/usr/bin/env bash
set -e

STAMP_FILE=\"${PROTOBUFC_BUILD}/configured.stamp\"
VERSION_FILE=\"${PROTOBUFC_VERSION_FILE}\"
CURRENT_VERSION=\"${PROTOBUFC_TAG}\"

# Detect previous version
if [ -f \"$VERSION_FILE\" ]; then
  PREV_VERSION=\$(cat \"$VERSION_FILE\")
else
  PREV_VERSION=\"\"
fi

if [ -f \"$STAMP_FILE\" ] && [ \"\$PREV_VERSION\" == \"\$CURRENT_VERSION\" ]; then
  echo \"[protobuf-c] Already configured for version \$CURRENT_VERSION, skipping.\"
  exit 0
fi

echo \"[protobuf-c] Configuring protobuf-c (\$CURRENT_VERSION)...\"
cd \"${PROTOBUFC_SOURCE}\"

# Ensure autogen.sh exists and is executable
if [ -x ./autogen.sh ]; then
  ./autogen.sh
elif [ -x ./autogen ]; then
  ./autogen
else
  echo \"[protobuf-c] Warning: autogen.sh not found — skipping autogen.\"
fi

./configure --prefix=\"${PROTOBUFC_INSTALL}\"

echo \"\$CURRENT_VERSION\" > \"$VERSION_FILE\"
touch \"$STAMP_FILE\"
")

# ---------------------------------------------------------------------------
# build.sh
# ---------------------------------------------------------------------------
file(WRITE ${PROTOBUFC_SCRIPTS}/build.sh
        "#!/usr/bin/env bash
set -e
STAMP_FILE=\"${PROTOBUFC_BUILD}/built.stamp\"

if [ -f \"$STAMP_FILE\" ]; then
  echo \"[protobuf-c] Already built, skipping.\"
  exit 0
fi

echo \"[protobuf-c] Building...\"
cd \"${PROTOBUFC_SOURCE}\"
make -j${NPROC_STR}

touch \"$STAMP_FILE\"
")

# ---------------------------------------------------------------------------
# install.sh
# ---------------------------------------------------------------------------
file(WRITE ${PROTOBUFC_SCRIPTS}/install.sh
        "#!/usr/bin/env bash
set -e
STAMP_FILE=\"${PROTOBUFC_BUILD}/installed.stamp\"

if [ -f \"$STAMP_FILE\" ]; then
  echo \"[protobuf-c] Already installed, skipping.\"
  exit 0
fi

echo \"[protobuf-c] Installing...\"
cd \"${PROTOBUFC_SOURCE}\"
make install

touch \"$STAMP_FILE\"
")

# ---------------------------------------------------------------------------
# Make scripts executable
# ---------------------------------------------------------------------------
file(GLOB SCRIPT_FILES ${PROTOBUFC_SCRIPTS}/*.sh)
foreach(script ${SCRIPT_FILES})
    file(COPY ${script} DESTINATION ${PROTOBUFC_SCRIPTS}
            FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
endforeach()

# ---------------------------------------------------------------------------
# ExternalProject_Add
# ---------------------------------------------------------------------------
ExternalProject_Add(protobuf_c_externalproject
        GIT_REPOSITORY ${PROTOBUFC_REPO}
        GIT_TAG        ${PROTOBUFC_TAG}
        GIT_SHALLOW    ON

        SOURCE_DIR     ${PROTOBUFC_SOURCE}
        BINARY_DIR     ${PROTOBUFC_BUILD}
        INSTALL_DIR    ${PROTOBUFC_INSTALL}

        CONFIGURE_COMMAND bash ${PROTOBUFC_SCRIPTS}/configure.sh
        BUILD_COMMAND     bash ${PROTOBUFC_SCRIPTS}/build.sh
        INSTALL_COMMAND   bash ${PROTOBUFC_SCRIPTS}/install.sh

        BUILD_BYPRODUCTS
        ${PROTOBUFC_INSTALL}/lib/libprotobuf-c.a
        ${PROTOBUFC_BUILD}/installed.stamp

        USES_TERMINAL_DOWNLOAD YES
        USES_TERMINAL_CONFIGURE YES
        USES_TERMINAL_BUILD YES
        USES_TERMINAL_INSTALL YES

        DEPENDS protobuf_externalproject
)

# ---------------------------------------------------------------------------
# Define CMake target
# ---------------------------------------------------------------------------
add_library(protobuf-c INTERFACE)
target_include_directories(protobuf-c INTERFACE ${PROTOBUFC_INSTALL}/include)
target_link_libraries(protobuf-c INTERFACE ${PROTOBUFC_INSTALL}/lib/libprotobuf-c.a)
add_dependencies(protobuf-c protobuf_c_externalproject)
