# $ROOT/external/uWebSockets/Findlsquic.cmake
cmake_minimum_required(VERSION 3.24)
include(FetchContent)
FetchContent_Declare(
        uWebSockets
        GIT_REPOSITORY https://github.com/uNetworking/uWebSockets
        GIT_TAG v20.72.0
        GIT_SHALLOW OFF
        GIT_SUBMODULES
)
FetchContent_MakeAvailable(uWebSockets)
add_library(uWebSockets INTERFACE)
target_include_directories(uWebSockets INTERFACE ${ZLIB_INCLUDE_DIR} ${uwebsockets_SOURCE_DIR}/src/ lsquic ${usockets_content_SOURCE_DIR}/src ${usockets_content_SOURCE_DIR}/src/eventing ${usockets_content_SOURCE_DIR}/src/crypto ${usockets_content_SOURCE_DIR}/src/internal/eventing ${usockets_content_SOURCE_DIR}/src/internal/networking ${BORINGSSL_INCLUDE_DIR} ${LSQUIC_INCLUDE_DIR} ${LIBURING_INCLUDE_DIR})
target_link_libraries(uWebSockets INTERFACE libuv uSockets ${ZLIB_LIBRARY})
