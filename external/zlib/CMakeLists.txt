# $ROOT/external/zlib/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
include(ExternalProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

ExternalProject_Add(zlib_externalproject
        GIT_REPOSITORY https://github.com/madler/zlib
        GIT_TAG master
        GIT_SHALLOW ON
        SOURCE_DIR  ${CMAKE_SOURCE_DIR}/external/zlib/source
        BINARY_DIR ${CMAKE_SOURCE_DIR}/external/zlib/bin
        CONFIGURE_COMMAND ${CMAKE_COMMAND} ../source -DCMAKE_BUILD_TYPE=Release
        BUILD_COMMAND ${CMAKE_COMMAND} --build ../bin
        INSTALL_COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/external/zlib/bin/zconf.h ${CMAKE_SOURCE_DIR}/external/zlib/source
        TEST_COMMAND ""
        BUILD_BYPRODUCTS ${CMAKE_SOURCE_DIR}/external/zlib/bin/libz.so
        USES_TERMINAL_DOWNLOAD true
        USES_TERMINAL_UPDATE true
        USES_TERMINAL_PATCH true
        USES_TERMINAL_CONFIGURE true
        USES_TERMINAL_BUILD true
        USES_TERMINAL_INSTALL true
        USES_TERMINAL_TEST true
)
install()
ExternalProject_Get_Property(zlib_externalproject SOURCE_DIR)
ExternalProject_Get_Property(zlib_externalproject BINARY_DIR)
set(ZLIB_INCLUDE_DIR  ${SOURCE_DIR} PARENT_SCOPE)
set(ZLIB_LIBRARY ${BINARY_DIR}/libz.so PARENT_SCOPE)
add_library(zlib SHARED IMPORTED)
#target_include_directories(zlib INTERFACE ${SOURCE_DIR}/src)
#target_link_libraries(zlib INTERFACE ${BINARY_DIR}/libz.so)
set_target_properties(zlib PROPERTIES IMPORTED_LOCATION ${BINARY_DIR}/libz.so)
set_target_properties (zlib PROPERTIES
        IMPORTED_LOCATION ${BINARY_DIR}/libz.so
        INTERFACE_INCLUDE_DIRECTORIES ${SOURCE_DIR}
)