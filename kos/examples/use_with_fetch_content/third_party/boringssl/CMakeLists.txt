# © 2024 AO Kaspersky Lab
# Licensed under the OpenSSL License

include(FetchContent)

set(FETCHCONTENT_QUIET FALSE)

FetchContent_Declare(BoringSSL
  GIT_REPOSITORY "https://github.com/KasperskyLab/boringssl-kos.git"
  GIT_SHALLOW TRUE
  GIT_PROGRESS TRUE
)
FetchContent_MakeAvailable(BoringSSL)

if(TARGET ssl AND TARGET crypto)
  set(BORINGSSL_INCLUDE_DIR "${BoringSSL_SOURCE_DIR}/src/include")
  target_include_directories(ssl INTERFACE "${BORINGSSL_INCLUDE_DIR}")
  target_include_directories(crypto INTERFACE "${BORINGSSL_INCLUDE_DIR}")
  add_library(BoringSSL::ssl ALIAS ssl)
  add_library(BoringSSL::crypto ALIAS crypto)
else()
  message(FATAL_ERROR "BoringSSL targets not found")
endif()
