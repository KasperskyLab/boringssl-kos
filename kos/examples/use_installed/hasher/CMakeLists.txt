# © 2025 AO Kaspersky Lab
# Licensed under the OpenSSL License

project(hasher)

# Include the CMake library named nk for working with the NK compiler (nk-gen-c).
include(platform/nk)

# Set the linker and compiler flags.
project_header_default("STANDARD_GNU_17:YES" "STRICT_WARNINGS:NO")

generate_edl_file(Hasher PREFIX examples)
nk_build_edl_files(hasher_edl_files NK_MODULE examples EDL "${EDL_FILE}")

add_executable(Hasher "${EXAMPLES_ROOT_DIR}/common/src/main.cpp")
add_dependencies(Hasher hasher_edl_files)
target_compile_features(Hasher PRIVATE cxx_std_17)

if(NOT BORINGSSL_INSTALL_DIR)
  message(FATAL_ERROR "BORINGSSL_INSTALL_DIR not specified")
endif()
set(OPENSSL_ROOT_DIR "${BORINGSSL_INSTALL_DIR}")

if(USE_OPENSSL_CMAKE_FIND_MODULE)
  # In this case BORINGSSL_INSTALL_DIR should be added to CMAKE_FIND_ROOT_PATH
  # with PREPEND because in opposite case OpenSSL from KasperskyOS sysroot will be found.
  list(PREPEND CMAKE_FIND_ROOT_PATH "${BORINGSSL_INSTALL_DIR}")
  find_package(OpenSSL REQUIRED)

  target_include_directories(Hasher BEFORE PRIVATE ${OPENSSL_INCLUDE_DIR})
  target_link_libraries(Hasher PRIVATE ${OPENSSL_LIBRARIES})
else()
  # In this case no matter how to add BORINGSSL_INSTALL_DIR to CMAKE_FIND_ROOT_PATH
  # so use APPEND here.
  list(APPEND CMAKE_FIND_ROOT_PATH "${BORINGSSL_INSTALL_DIR}")
  find_package(BoringSSL REQUIRED)
  target_link_libraries(Hasher PRIVATE BoringSSL::crypto)
endif()
