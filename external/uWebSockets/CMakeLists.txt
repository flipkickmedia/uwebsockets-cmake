# $ROOT/external/uWebSockets/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)

include(FetchContent)

# Fetch uWebSockets (headers-only, links to our separately-built usockets target)
FetchContent_Declare(
        uwebsockets_content
        GIT_REPOSITORY https://github.com/uNetworking/uWebSockets
        GIT_TAG        v20.74.0
        GIT_SHALLOW    TRUE
        SOURCE_DIR     ${CMAKE_SOURCE_DIR}/external/uWebSockets/source
)
FetchContent_MakeAvailable(uwebsockets_content)

# Header-only wrapper; consumers just link uwebsockets and get includes + usockets
add_library(uwebsockets INTERFACE)
target_include_directories(uwebsockets INTERFACE
        ${uwebsockets_content_SOURCE_DIR}/src
)

# Link to the usockets target defined by your new uSockets CMake
target_link_libraries(uwebsockets INTERFACE usockets)