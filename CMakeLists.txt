# $ROOT/CMakeLists.txt
cmake_minimum_required(VERSION 3.24 FATAL_ERROR)
project(entitywind LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 23)

add_subdirectory(external)

add_executable(Server server_ws.cc)
target_link_libraries(Server
        PRIVATE
        uwebsockets       # brings in usockets; usockets brings in liburing (with IO_URING ON)
        zlib
)
