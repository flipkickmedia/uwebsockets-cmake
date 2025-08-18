# uwebsockets-cmake
A cmake build system for uWebSockets https://github.com/uNetworking/uWebSockets

# Boilerplate
This repository provides a cmake build system for uWebSockets and is compatible with v20.72.0

You can extend this and build your own c++/c programs if you edit the CMakeLists.txt in the root of the repo.

# Status
Currently this repo is described as working although significant cleanup needed in the cmake build system is needed.

# Build details
This system builds all of the required libraries from source so you should be able to make a portable executable if you copy the so files

# Linux only
This only works with linux at the minute unless there is demand for a Windows/Mac version

# Building
To build the repository change directory to the root of the repository and run:
```shell
cmake . -DCMAKE_BUILD_TYPE=Release
cmake --build .
```