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
To build the repository change directory to the root of the repository and run:
```
mkdir build
cd build && cmake ../ -DCMAKE_BUILD_TYPE=Release && cmake --build .
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
