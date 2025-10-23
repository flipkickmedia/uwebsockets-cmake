# $ROOT/external/uSockets/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
project(uSocketsExternal LANGUAGES C CXX)
set(CMAKE_C_STANDARD 11)

# Expect options to be defined by the parent (external/CMakeLists.txt)
foreach(_opt USE_LIBUV USE_IO_URING USE_EPOLL USE_SSL USE_QUIC)
    if(NOT DEFINED ${_opt})
        message(FATAL_ERROR
                "Expected ${_opt} to be defined by the parent external/CMakeLists.txt")
    endif()
endforeach()

# Fetch uSockets source
include(FetchContent)
FetchContent_Declare(usockets
        GIT_REPOSITORY https://github.com/uNetworking/uSockets.git
        GIT_TAG        master
        GIT_SHALLOW    TRUE
        SOURCE_DIR     ${CMAKE_SOURCE_DIR}/external/uSockets/source
)
FetchContent_MakeAvailable(usockets)
set(USRC ${usockets_SOURCE_DIR}/src)

# Select backend string (parent already validated exclusivity)
if(USE_LIBUV)
    set(_BACKEND "libuv")
elseif(USE_IO_URING)
    set(_BACKEND "io_uring")
elseif(USE_EPOLL)
    set(_BACKEND "epoll")
endif()

# Safety checks
if(USE_SSL AND USE_IO_URING)
    message(FATAL_ERROR "io_uring backend cannot be used with OpenSSL/BoringSSL.")
endif()
if(USE_QUIC AND NOT USE_SSL)
    message(FATAL_ERROR "USE_QUIC=ON requires USE_SSL=ON (lsquic depends on SSL).")
endif()
if(USE_SSL AND NOT (USE_LIBUV OR USE_EPOLL))
    message(FATAL_ERROR "With SSL=ON, backend must be libuv or epoll.")
endif()

# Require only deps needed for chosen features
if(_BACKEND STREQUAL "libuv")
    if(NOT TARGET Libuv::uv_a)
        message(FATAL_ERROR "Libuv::uv_a target not found. Build/export libuv first.")
    endif()
elseif(_BACKEND STREQUAL "io_uring")
    if(NOT TARGET liburing)
        message(FATAL_ERROR "liburing target not found. Build/export liburing first.")
    endif()
endif()

if(USE_SSL)
    if(NOT TARGET BoringSSL::ssl OR NOT TARGET BoringSSL::crypto)
        message(FATAL_ERROR "BoringSSL::ssl / ::crypto not found. Build/export BoringSSL first.")
    endif()
endif()

if(USE_QUIC)
    if(NOT TARGET Lsquic::lsquic)
        message(FATAL_ERROR "Lsquic::lsquic target not found. Build/export lsquic first.")
    endif()
    if(NOT TARGET Libevent::event)
        message(FATAL_ERROR "Libevent::event target not found. Build/export libevent first.")
    endif()
    if(NOT TARGET zlib)
        message(FATAL_ERROR "zlib target not found. Build/export zlib first.")
    endif()
endif()

# Sources
set(USOCKETS_SOURCES
        ${USRC}/bsd.c
        ${USRC}/loop.c
        ${USRC}/context.c
        ${USRC}/socket.c
)

if(_BACKEND STREQUAL "libuv")
    list(APPEND USOCKETS_SOURCES ${USRC}/eventing/libuv.c)
elseif(_BACKEND STREQUAL "io_uring")
    list(APPEND USOCKETS_SOURCES
            ${USRC}/io_uring/io_loop.c
            ${USRC}/io_uring/io_socket.c
            ${USRC}/io_uring/io_context.c
    )
elseif(_BACKEND STREQUAL "epoll")
    list(APPEND USOCKETS_SOURCES ${USRC}/eventing/epoll_kqueue.c)
endif()

if(USE_SSL)
    list(APPEND USOCKETS_SOURCES
            ${USRC}/crypto/openssl.c
            ${USRC}/crypto/sni_tree.cpp
    )
endif()

add_library(usockets STATIC ${USOCKETS_SOURCES})
set_target_properties(usockets PROPERTIES POSITION_INDEPENDENT_CODE ON)

# Includes
target_include_directories(usockets
        PUBLIC
        ${USRC}  # for <libusockets.h>
        PRIVATE
        ${USRC}/internal
        ${USRC}/internal/eventing
        ${USRC}/internal/networking
)
if(USE_SSL)
    target_include_directories(usockets PRIVATE ${USRC}/crypto)
endif()
if(_BACKEND STREQUAL "io_uring")
    target_include_directories(usockets PRIVATE ${USRC}/io_uring)
endif()

# Compile defs
if(USE_SSL)
    target_compile_definitions(usockets PRIVATE LIBUS_USE_OPENSSL)
else()
    target_compile_definitions(usockets PRIVATE LIBUS_NO_SSL)
endif()

if(_BACKEND STREQUAL "libuv")
    target_compile_definitions(usockets PRIVATE LIBUS_USE_LIBUV)
elseif(_BACKEND STREQUAL "io_uring")
    target_compile_definitions(usockets PRIVATE LIBUS_USE_IO_URING)
elseif(_BACKEND STREQUAL "epoll")
    target_compile_definitions(usockets PRIVATE LIBUS_USE_EPOLL)
endif()

if(USE_QUIC)
    target_compile_definitions(usockets PRIVATE LIBUS_USE_QUIC)
endif()

# openssl.c needs the internal layout forced
if(USE_SSL)
    set_source_files_properties(
            ${USRC}/crypto/openssl.c
            PROPERTIES
            COMPILE_OPTIONS "-include;${USRC}/internal/internal.h"
    )
endif()

# Link deps
if(_BACKEND STREQUAL "libuv")
    target_link_libraries(usockets PUBLIC Libuv::uv_a)
elseif(_BACKEND STREQUAL "io_uring")
    target_link_libraries(usockets PUBLIC liburing)
endif()

if(USE_SSL)
    target_link_libraries(usockets PUBLIC BoringSSL::ssl BoringSSL::crypto)
endif()

if(USE_QUIC)
    target_link_libraries(usockets PUBLIC
            Lsquic::lsquic
            Libevent::event
            zlib
    )
endif()

message(STATUS "uSockets backend: ${_BACKEND} | SSL: ${USE_SSL} | QUIC: ${USE_QUIC}")
