/* We simply call the root header file "App.h", giving you uWS::App and uWS::SSLApp */
#include "App.h"
#include <ctime>
#include <iostream>

#include <sstream>
#include <cstdint>
#include <cstddef>

/* This is a simple WebSocket echo server example. */

/**
 * Get the port number from an environment variable.
 * Falls back to a default if unset or invalid.
 */
int get_port_from_env(const std::string& env_var_name, int default_port) {
    const char* env_value = std::getenv(env_var_name.c_str());

    if (!env_value) {
        std::cerr << "[INFO] Environment variable " << env_var_name
                  << " not set. Using default port " << default_port << ".\n";
        return default_port;
    }

    try {
        int port = std::stoi(env_value);

        if (port < 1 || port > 65535) {
            throw std::out_of_range("Port out of range");
        }

        std::cerr << "[INFO] Using port " << port
                  << " from environment variable " << env_var_name << ".\n";
        return port;
    } catch (const std::exception& e) {
        std::cerr << "[WARN] Invalid value for " << env_var_name
                  << " ('" << env_value << "'): " << e.what()
                  << ". Falling back to default port " << default_port << ".\n";
        return default_port;
    }
}


uint32_t crc32(const char *s, size_t n, uint32_t crc = 0xFFFFFFFF) {

    for (size_t i = 0; i < n; i++) {
        unsigned char ch = static_cast<unsigned char>(s[i]);
        for (size_t j = 0; j < 8; j++) {
            uint32_t b = (ch ^ crc) & 1;
            crc >>= 1;
            if (b) crc = crc ^ 0xEDB88320;
            ch >>= 1;
        }
    }

    return crc;
}

//todo add check for cert files and exit if they are not found otherwise a segfault happens on
int main() {

    int port = get_port_from_env("SERVER_PORT", 900);

    /* ws->getUserData returns one of these */
    struct PerSocketData {
        /* Fill with user data */
    };

    /* Keep in mind that uWS::SSLApp({options}) is the same as uWS::App() when compiled without SSL support.
     * You may swap to using uWS:App() if you don't need SSL */
    uWS::SSLApp app = uWS::SSLApp({
        /* There are example certificates in uWebSockets.js repo */
        .key_file_name = "../misc/privkey.pem",
        .cert_file_name = "../misc/fullchain.pem",
        .passphrase = "1234"
    }).ws<PerSocketData>("/*", {
        /* Settings */
        .compression = uWS::SHARED_COMPRESSOR,
        .maxPayloadLength = 16 * 1024 * 1024,
        .idleTimeout = 16,
        .maxBackpressure = 1 * 1024 * 1024,
        .closeOnBackpressureLimit = false,
        .resetIdleTimeoutOnSend = false,
        .sendPingsAutomatically = true,
        /* Handlers */
        .upgrade = nullptr,
        .open = [](auto *ws) {
            /* Open event here, you may access ws->getUserData() which points to a PerSocketData struct */
            ws->subscribe("broadcast");
        },
        .message = [&app](auto *ws, std::string_view message, uWS::OpCode opCode) {
            int test = ws->send(message);
        },
        .drain = [](auto */*ws*/) {
            /* Check ws->getBufferedAmount() here */
        },
        .ping = [](auto */*ws*/, std::string_view) {
            /* Not implemented yet */
        },
        .pong = [](auto */*ws*/, std::string_view) {
            /* Not implemented yet */
        },
        .close = [](auto *ws, int code, std::string_view message) {
            /* You may access ws->getUserData() here */
            ws->getUserData();
        }
    }).get("/defs.json", [](auto *res, auto *req) {

        /* Display the headers */
        std::cout << " --- " << req->getUrl() << " --- " << std::endl;
        for (auto [key, value] : *req) {
            std::cout << key << ": " << value << std::endl;
        }

        auto isAborted = std::make_shared<bool>(false);
        uint32_t crc = 0xFFFFFFFF;
        res->onData([res, isAborted, crc, req](std::string_view chunk, bool isFin) mutable {
            std::cout << " --- data:" << req->getUrl() << " --- " << std::endl;
            if (chunk.length()) {
                crc = crc32(chunk.data(), chunk.length(), crc);
            }

            if (isFin && !*isAborted) {
                std::stringstream s;
                s << std::hex << (~crc) << std::endl;
                res->end(s.str());
            }
        });

        res->onAborted([isAborted]() {
            *isAborted = true;
        });
    }).listen("127.0.0.1", port, [&port](auto *listen_socket) {
        if (listen_socket) {
            std::cout << "Listening on port " << port << std::endl;
        }
    });

    app.run();
}

