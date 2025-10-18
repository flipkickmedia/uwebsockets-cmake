# $ROOT/CMakeLists.txt
cmake_minimum_required(VERSION 3.24 FATAL_ERROR)
project(entitywind LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 23)
add_subdirectory(external)
add_executable(Server server_ws.cc)
target_link_libraries(Server
        zlib
        uWebSockets
        ${BORINGSSL_LIB_SSL}
        ${BORINGSSL_LIB_CRYPTO}
)
add_dependencies(Server
        zlib_externalproject
        libevent_externalproject
        lsquic_externalproject
        liburing_externalproject
        libuv_externalproject
        boringssl_externalproject
)
