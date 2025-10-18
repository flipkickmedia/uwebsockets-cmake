# $ROOT/external/zlib/CMakeLists.txt
cmake_minimum_required(VERSION 3.24)
include(ExternalProject)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

ExternalProject_Add(zlib_externalproject
        GIT_REPOSITORY https://github.com/madler/zlib
        GIT_TAG master
        GIT_SHALLOW ON
        SOURCE_DIR ${CMAKE_SOURCE_DIR}/external/zlib/source
        BINARY_DIR ${CMAKE_SOURCE_DIR}/external/zlib/bin
        INSTALL_DIR ${CMAKE_SOURCE_DIR}/external/zlib/install
        CONFIGURE_COMMAND ${CMAKE_COMMAND}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${CMAKE_SOURCE_DIR}/external/zlib/install
        ../source
        BUILD_COMMAND ${CMAKE_COMMAND} --build ../bin
        INSTALL_COMMAND ${CMAKE_COMMAND} --install ../bin --prefix ${CMAKE_SOURCE_DIR}/external/zlib/install
        #        INSTALL_COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/external/zlib/bin/zconf.h ${CMAKE_SOURCE_DIR}/external/zlib/source
        #        ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/external/zlib/bin/libz.a ${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.a
        #        ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/external/zlib/bin/libz.so ${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.so
        #        ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/external/zlib/bin/libz.so.1 ${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.so.1
        #        ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/external/zlib/bin/libz.so.1.3.1 ${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.so.1.3.1
        #        ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/external/zlib/bin/zlib.pc ${CMAKE_SOURCE_DIR}/external/zlib/install/lib/zlib.pc
        TEST_COMMAND ""
        BUILD_BYPRODUCTS ${CMAKE_SOURCE_DIR}/external/zlib/install/lib/libz.a
        USES_TERMINAL_DOWNLOAD true
        USES_TERMINAL_UPDATE true
        USES_TERMINAL_PATCH true
        USES_TERMINAL_CONFIGURE true
        USES_TERMINAL_BUILD true
        USES_TERMINAL_INSTALL true
        USES_TERMINAL_TEST true
)
ExternalProject_Get_Property(zlib_externalproject SOURCE_DIR)
ExternalProject_Get_Property(zlib_externalproject BINARY_DIR)
ExternalProject_Get_Property(zlib_externalproject INSTALL_DIR)
set(ZLIB_INCLUDE_DIR ${INSTALL_DIR}/include PARENT_SCOPE)
set(ZLIB_LIBRARY ${INSTALL_DIR}/lib/libz.a PARENT_SCOPE)
add_library(zlib STATIC IMPORTED GLOBAL)
#target_include_directories(zlib INTERFACE ${SOURCE_DIR}/src)
#target_link_libraries(zlib INTERFACE ${BINARY_DIR}/libz.so)
file(MAKE_DIRECTORY ${INSTALL_DIR}/include)
set_target_properties(zlib PROPERTIES
        IMPORTED_LOCATION ${INSTALL_DIR}/lib/libz.a
        INTERFACE_INCLUDE_DIRECTORIES ${INSTALL_DIR}/include
)
add_dependencies(zlib zlib_externalproject)