# $ROOT/external/uSockets/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
project(uSocketsFromSubmodule LANGUAGES C CXX)
set(CMAKE_C_STANDARD 11)

# ---- Options ---------------------------------------------------------------
option(USE_IO_URING "Build uSockets with io_uring backend" OFF)
option(USE_LIBUV    "Build uSockets with libuv backend"   OFF)
option(USE_QUIC     "Enable QUIC via lsquic"              OFF)
option(USE_SSL      "Enable OpenSSL/BoringSSL support"    ON)

# Disallow SSL with io_uring (current incompatibility)
if (USE_IO_URING AND USE_SSL)
    message(FATAL_ERROR "io_uring backend cannot be used with OpenSSL/BoringSSL right now. "
            "Disable USE_SSL or switch to another backend.")
endif()

# QUIC needs SSL
if (USE_QUIC AND NOT USE_SSL)
    message(FATAL_ERROR "USE_QUIC requires USE_SSL=ON (lsquic depends on SSL).")
endif()

# ---- uSockets source tree --------------------------------------------------
if (NOT DEFINED UWS_ROOT OR NOT DEFINED USOCKETS_SRC_DIR)
    set(UWS_ROOT         "${CMAKE_SOURCE_DIR}/external/uWebSockets/source")
    set(USOCKETS_SRC_DIR "${UWS_ROOT}/uSockets/src")
endif ()
if (NOT EXISTS "${USOCKETS_SRC_DIR}/loop.c")
    message(FATAL_ERROR "USOCKETS_SRC_DIR seems wrong: ${USOCKETS_SRC_DIR}")
endif ()

# ---- Sources ---------------------------------------------------------------
set(USOCKETS_SOURCES
        ${USOCKETS_SRC_DIR}/bsd.c
        ${USOCKETS_SRC_DIR}/loop.c
        ${USOCKETS_SRC_DIR}/context.c
        ${USOCKETS_SRC_DIR}/socket.c
)

# SSL sources only when enabled
if (USE_SSL)
    list(APPEND USOCKETS_SOURCES
            ${USOCKETS_SRC_DIR}/crypto/openssl.c
            ${USOCKETS_SRC_DIR}/crypto/sni_tree.cpp
    )
endif ()

# io_uring sources only when enabled
if (USE_IO_URING)
    list(APPEND USOCKETS_SOURCES
            ${USOCKETS_SRC_DIR}/io_uring/io_loop.c
            ${USOCKETS_SRC_DIR}/io_uring/io_socket.c
            ${USOCKETS_SRC_DIR}/io_uring/io_context.c
    )
endif ()

add_library(usockets STATIC ${USOCKETS_SOURCES})
set_target_properties(usockets PROPERTIES POSITION_INDEPENDENT_CODE ON)

# Inject internal layout for openssl.c (only if building SSL)
if (USE_SSL)
    set_source_files_properties(
            ${USOCKETS_SRC_DIR}/crypto/openssl.c
            PROPERTIES
            COMPILE_OPTIONS "-include;${USOCKETS_SRC_DIR}/internal/internal.h"
    )
endif ()

# ---- Includes for the uSockets tree itself --------------------------------
target_include_directories(usockets
        PRIVATE
        ${USOCKETS_SRC_DIR}
        ${USOCKETS_SRC_DIR}/internal
        ${USOCKETS_SRC_DIR}/internal/eventing
        ${USOCKETS_SRC_DIR}/internal/networking
)

if (USE_SSL)
    target_include_directories(usockets PRIVATE ${USOCKETS_SRC_DIR}/crypto)
endif ()
if (USE_IO_URING)
    target_include_directories(usockets PRIVATE ${USOCKETS_SRC_DIR}/io_uring)
endif ()

# ---- Compile defs ----------------------------------------------------------
target_compile_definitions(usockets PRIVATE LIBUS_INTERNAL)

if (USE_SSL)
    target_compile_definitions(usockets PRIVATE LIBUS_USE_OPENSSL)
else ()
    target_compile_definitions(usockets PRIVATE LIBUS_NO_SSL)
endif ()

if (USE_IO_URING)
    target_compile_definitions(usockets PRIVATE LIBUS_USE_IO_URING)
endif ()
if (USE_LIBUV)
    target_compile_definitions(usockets PRIVATE LIBUS_USE_LIBUV)
endif ()
if (USE_QUIC)
    target_compile_definitions(usockets PRIVATE LIBUS_USE_QUIC)
endif ()

# ---- Link third-party deps via modern targets ------------------------------
# SSL deps only when enabled
if (USE_SSL)
    target_link_libraries(usockets
            PUBLIC
            BoringSSL::ssl
            BoringSSL::crypto
    )
endif ()

# Backend deps (always static variants)
if (USE_IO_URING)
    target_link_libraries(usockets PUBLIC liburing)
endif ()
if (USE_LIBUV)
    target_link_libraries(usockets PUBLIC Libuv::uv_a)
endif ()

# QUIC deps when enabled
if (USE_QUIC)
    target_link_libraries(usockets PUBLIC
            Lsquic::lsquic
            Libevent::event
            zlib
    )
endif ()