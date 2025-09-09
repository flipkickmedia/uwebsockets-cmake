#_deps
rm -rf _deps
rm -rf CMakeFiles
rm -rf CMakeCache.txt
rm -rf cmake-build-debug
rm -rf cmake-build-release
rm -rf Makefile

#external
rm -rf external/Makefile
rm -rf external/CMakeFiles

#boringssl
rm -rf external/boringssl/source
rm -rf external/boringssl/bin
rm -rf external/boringssl/CMakeFiles
rm -rf external/boringssl/Makefile
rm -rf external/boringssl/boringssl_externalproject-prefix

#libevent
rm -rf external/libevent/source
rm -rf external/libevent/bin
rm -rf external/libevent/CMakeFiles
rm -rf external/libevent/Makefile
rm -rf external/libevent/libevent_externalproject-prefix

#liburing
rm -rf external/liburing/source
rm -rf external/liburing/bin
rm -rf external/liburing/CMakeFiles
rm -rf external/liburing/Makefile
rm -rf external/liburing/liburing_externalproject-prefix

#libuv
rm -rf external/libuv/source
rm -rf external/libuv/bin
rm -rf external/libuv/CMakeFiles
rm -rf external/libuv/Makefile
rm -rf external/libuv/libuv_externalproject-prefix

#lsquic
rm -rf external/lsquic/source
rm -rf external/lsquic/bin
rm -rf external/lsquic/CMakeFiles
rm -rf external/lsquic/Makefile
rm -rf external/lsquic/lsquic_externalproject-prefix

#usockets
rm -rf external/uSockets/source
rm -rf external/uSockets/bin
rm -rf external/uSockets/CMakeFiles
rm -rf external/uSockets/Makefile

#uWebsockets
rm -rf external/uWebSockets/CMakeFiles
rm -rf external/uWebSockets/Makefile

#zlib
rm -rf external/zlib/source
rm -rf external/zlib/bin
rm -rf external/zlib/CMakeFiles
rm -rf external/zlib/Makefile
rm -rf external/zlib/zlib_externalproject-prefix

#main
rm -rf cmake-build-debug

#certs
rm -rf misc/valid*
rm -rf misc/selfsigned*
rm -rf misc/invalid*
