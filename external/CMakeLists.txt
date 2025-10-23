# $ROOT/external/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)

# ---------- Global feature flags (single source of truth) ----------
option(USE_LIBUV    "Use libuv backend for uSockets"        ON)
option(USE_IO_URING "Use io_uring backend for uSockets"      OFF)
option(USE_EPOLL    "Use epoll/kqueue backend for uSockets"  OFF)
option(USE_SSL      "Enable SSL (BoringSSL) in uSockets"     OFF)
option(USE_QUIC     "Enable QUIC via lsquic"                 OFF)

# ---------- Validate combinations ----------
# Count selected backends
set(_BACKENDS 0)
if(USE_LIBUV)
    math(EXPR _BACKENDS "${_BACKENDS}+1")
endif()
if(USE_IO_URING)
    math(EXPR _BACKENDS "${_BACKENDS}+1")
endif()
if(USE_EPOLL)
    math(EXPR _BACKENDS "${_BACKENDS}+1")
endif()

if(_BACKENDS GREATER 1)
    message(FATAL_ERROR
            "Select exactly ONE uSockets backend.\n"
            "  USE_LIBUV=${USE_LIBUV}\n"
            "  USE_IO_URING=${USE_IO_URING}\n"
            "  USE_EPOLL=${USE_EPOLL}")
endif()

if(_BACKENDS EQUAL 0)
    message(STATUS "No backend selected; defaulting to libuv")
    set(USE_LIBUV ON CACHE BOOL "" FORCE)
endif()

# SSL currently not supported with io_uring
if(USE_SSL AND USE_IO_URING)
    message(FATAL_ERROR "io_uring backend cannot be combined with SSL right now.")
endif()

# QUIC requires SSL
if(USE_QUIC AND NOT USE_SSL)
    message(FATAL_ERROR "USE_QUIC requires USE_SSL=ON.")
endif()

# If SSL is ON, backend must be libuv or epoll
if(USE_SSL AND NOT (USE_LIBUV OR USE_EPOLL))
    message(FATAL_ERROR "With SSL=ON, backend must be libuv or epoll.")
endif()

# ---------- Deps (only what’s needed) ----------
add_subdirectory(zlib)

if(USE_IO_URING)
    add_subdirectory(liburing)
endif()

if(USE_LIBUV)
    add_subdirectory(libuv)
endif()

if(USE_SSL)
    add_subdirectory(boringssl)
endif()

if(USE_QUIC)
    add_subdirectory(libevent)
    add_subdirectory(lsquic)
endif()

# ---------- Core libs ----------
add_subdirectory(uSockets)    # consumes USE_* options
add_subdirectory(uWebSockets) # header-only wrapper that links to usockets
