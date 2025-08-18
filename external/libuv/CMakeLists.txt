# $ROOT/external/libuv/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
include(ExternalProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

ExternalProject_Add(libuv_externalproject
        GIT_REPOSITORY https://github.com/libuv/libuv
        GIT_TAG v1.x
        GIT_SHALLOW ON
        SOURCE_DIR  ${CMAKE_SOURCE_DIR}/external/libuv/source
        BINARY_DIR ${CMAKE_SOURCE_DIR}/external/libuv/bin
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
        ../source
        -DCMAKE_BUILD_TYPE=Release
        BUILD_COMMAND ${CMAKE_COMMAND} --build ../bin
        INSTALL_COMMAND ""
        TEST_COMMAND ""
        BUILD_BYPRODUCTS ${CMAKE_SOURCE_DIR}/external/libuv/bin/libuv.so
        USES_TERMINAL_DOWNLOAD true
        USES_TERMINAL_UPDATE true
        USES_TERMINAL_PATCH true
        USES_TERMINAL_CONFIGURE true
        USES_TERMINAL_BUILD true
        USES_TERMINAL_INSTALL true
        USES_TERMINAL_TEST true
)
ExternalProject_Get_Property(libuv_externalproject SOURCE_DIR)
ExternalProject_Get_Property(libuv_externalproject BINARY_DIR)
#set(LIBUV_INCLUDE  ${SOURCE_DIR}/include PARENT_SCOPE)
#set(LIBUV_LIBRARY  ${BINARY_DIR}/libuv.a PARENT_SCOPE)
add_library(libuv SHARED IMPORTED GLOBAL)
target_include_directories(libuv INTERFACE ${SOURCE_DIR}/src)
#this is one way
#target_link_libraries(libuv INTERFACE ${BINARY_DIR}/libuv.so)
#to do the same thing as this
set_target_properties (libuv PROPERTIES
        IMPORTED_LOCATION ${BINARY_DIR}/libuv.so
        INTERFACE_INCLUDE_DIRECTORIES ${SOURCE_DIR}/include
)