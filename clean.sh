#boringssl
rm -rf external/boringssl/source
rm -rf external/boringssl/bin

#libevent
rm -rf external/libevent/source
rm -rf external/libevent/bin

#liburing
rm -rf external/liburing/source
rm -rf external/liburing/bin

#libuv
rm -rf external/libuv/source
rm -rf external/libuv/bin

#lsquic
rm -rf external/lsquic/source
rm -rf external/lsquic/bin

#usockets
rm -rf external/uSockets/source
rm -rf external/uSockets/bin

#zlib
rm -rf external/zlib/source
rm -rf external/zlib/bin

#main
rm -rf cmake-build-debug

#certs
rm -rf misc/valid*
rm -rf misc/selfsigned*
rm -rf misc/invalid*
