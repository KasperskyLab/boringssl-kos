# © 2025 AO Kaspersky Lab
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

# Detect board.
if(CMAKE_SYSTEM_SOC STREQUAL "BCM2711")
  set(BOARD "RPI4_BCM2711")
elseif(CMAKE_SYSTEM_SOC STREQUAL "RK3568")
  set(BOARD "RADXA_ROCK_3A")
else()
  message(FATAL_ERROR "Unsupported board for SoC '${CMAKE_SYSTEM_SOC}'")
endif()

include(cmake/BoringSSL.cmake)

set(EXAMPLES_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/..")
include_directories(${EXAMPLES_ROOT_DIR})

add_subdirectory(hasher)
add_subdirectory(einit)
