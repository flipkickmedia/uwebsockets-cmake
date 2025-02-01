# $ROOT/external/uSockets/Findlsquic.cmake
cmake_minimum_required(VERSION 3.24)
set(CMAKE_C_STANDARD 11)
include(FetchContent)

FetchContent_Declare(
        uSockets_content
        GIT_REPOSITORY https://github.com/uNetworking/uSockets
        GIT_TAG 182b7e4
        GIT_SHALLOW ON
        GIT_SUBMODULES ""
        SOURCE_DIR  ${CMAKE_SOURCE_DIR}/external/uSockets/source
        BINARY_DIR ${CMAKE_SOURCE_DIR}/external/uSockets/bin
)
FetchContent_MakeAvailable(uSockets_content)
file(GLOB_RECURSE SOURCES ${usockets_content_SOURCE_DIR}/src/*.c ${usockets_content_SOURCE_DIR}/src/eventing/*.c ${usockets_content_SOURCE_DIR}/src/crypto/*.c ${usockets_content_SOURCE_DIR}/src/crypto/*.cpp ${usockets_content_SOURCE_DIR}/src/internal/eventing/* ${usockets_content_SOURCE_DIR}/src/internal/networking/*)
add_library(uSockets ${SOURCES})
add_dependencies(uSockets lsquic_externalproject boringssl_externalproject)
target_include_directories(uSockets PUBLIC lsquic ${usockets_content_SOURCE_DIR}/src ${usockets_content_SOURCE_DIR}/src/eventing ${usockets_content_SOURCE_DIR}/src/crypto ${usockets_content_SOURCE_DIR}/src/internal/eventing ${usockets_content_SOURCE_DIR}/src/internal/networking ${BORINGSSL_INCLUDE_DIR} ${LSQUIC_INCLUDE_DIR} ${LIBURING_INCLUDE_DIR})
target_link_libraries(uSockets lsquic ${BORINGSSL_LIB_SSL} ${BORINGSSL_LIB_CRYPTO})
target_compile_definitions(uSockets PRIVATE LIBUS_USE_OPENSSL LIBUS_USE_QUIC ) #LIBUS_USE_IO_URING