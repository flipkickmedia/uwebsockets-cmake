# $ROOT/external/uWebSockets/Findlsquic.cmake
cmake_minimum_required(VERSION 3.24)
include(FetchContent)
FetchContent_Declare(
        uWebSockets_content
        GIT_REPOSITORY https://github.com/uNetworking/uWebSockets
        GIT_TAG v20.74.0
        GIT_SHALLOW OFF
        GIT_SUBMODULES
)
FetchContent_MakeAvailable(uWebSockets_content)
add_library(uWebSockets INTERFACE)
target_include_directories(uWebSockets INTERFACE
        lsquic
        ${BORINGSSL_INCLUDE_DIR}
        ${LSQUIC_INCLUDE_DIR}
        ${LIBURING_INCLUDE_DIR}
        ${ZLIB_INCLUDE_DIR}
        ${uwebsockets_content_SOURCE_DIR}/src/
        ${usockets_content_SOURCE_DIR}/src
        ${usockets_content_SOURCE_DIR}/src/eventing
        ${usockets_content_SOURCE_DIR}/src/crypto
        ${usockets_content_SOURCE_DIR}/src/internal/eventing
        ${usockets_content_SOURCE_DIR}/src/internal/networking
)
target_link_libraries(uWebSockets INTERFACE libuv uSockets ${ZLIB_LIBRARY})
