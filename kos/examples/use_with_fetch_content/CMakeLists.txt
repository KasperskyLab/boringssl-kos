# © 2024 AO Kaspersky Lab
# Licensed under the OpenSSL License

cmake_minimum_required(VERSION 3.25)

project(hasher)

# Initialize CMake library for the KasperskyOS SDK.
include(platform)
# Statically link executable files.
initialize_platform(FORCE_STATIC)

# Include the CMake library named doxygen for documentation of source texts.
include(platform/doxygen)
add_project_documentation_main_target()

set(EXAMPLES_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/..")
include_directories(${EXAMPLES_ROOT_DIR})

add_subdirectory(third_party/boringssl EXCLUDE_FROM_ALL)
add_subdirectory(hasher)
add_subdirectory(einit)
