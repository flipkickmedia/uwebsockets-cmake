# uwebsockets-cmake
A cmake build system for uWebSockets https://github.com/uNetworking/uWebSockets

# Boilerplate
This repository provides a modern cmake build system for uWebSockets and is compatible with v20.74.0

You can extend this and build your own c++/c programs if you edit the CMakeLists.txt in the root of the repo.

# Status
Currently, this repo is described as working although significant cleanup needed in the cmake build system is needed.

# Build details
This system builds the required libraries from source so you should be able to make a portable executable if you copy the .so files

# Linux only
This only works with linux at the minute unless there is demand for a Windows/Mac version

# Building

## Defaults
To build the repository change directory to the root of the repository and run:
```shell
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```
This will configure and build inside a directory named build.

## SSL
To enable SSL, you have to choose between using EPOLL and UV backends. As of uWebSockets v20.74.0 IO_URING doesn't work with SSL.

```shell
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DUSE_IO_URING=OFF -DUSE_LIBUV=ON -DUSE_SSL=ON -DUSE_QUIC=OFF
cmake --build build -j
```

# Running
Depending on your system, youll need to install a few packages to allow ./Server to run:

```shell
sudo apt-get install --only-upgrade libstdc++6
```

```shell
sudo SERVER_PORT=1234 ./Server
[INFO] Using port 1234 from environment variable SERVER_PORT.
Listening on port 1234
```

# systemd Service File
