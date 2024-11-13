# © 2024 AO Kaspersky Lab
# Licensed under the OpenSSL License

set(BORINGSSL_ROOT_DIR "${CMAKE_SOURCE_DIR}/third_party/boringssl")

if(EXISTS "${BORINGSSL_ROOT_DIR}/CMakeLists.txt")
  add_subdirectory(${BORINGSSL_ROOT_DIR})
  if(TARGET ssl AND TARGET crypto)
    set(BORINGSSL_INCLUDE_DIR "${BORINGSSL_ROOT_DIR}/src/include")
    target_include_directories(ssl INTERFACE "${BORINGSSL_INCLUDE_DIR}")
    target_include_directories(crypto INTERFACE "${BORINGSSL_INCLUDE_DIR}")
    add_library(BoringSSL::ssl ALIAS ssl)
    add_library(BoringSSL::crypto ALIAS crypto)
  else()
    message(FATAL_ERROR "BoringSSL targets not found")
  endif()
else()
  message(FATAL_ERROR "No CMakeLists.txt found for BoringSSL in '${BORINGSSL_ROOT_DIR}'")
endif()
