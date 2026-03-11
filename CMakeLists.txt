# © 2026 AO Kaspersky Lab
# Licensed under the MIT License

cmake_minimum_required (VERSION 3.29)

project (BoringSSL-kos LANGUAGES C CXX)

include (FetchContent)

# Disable assembly optimizations for BCM2711 SoC.
# Raspberry Pi 4 lacks ARMv8 Cryptographic Extension support.
if ("${CMAKE_SYSTEM_SOC}" MATCHES "BCM2711")
    set (OPENSSL_NO_ASM 1)
endif ()

# Configure the source location and patch application for the BoringSSL library.
# The official BoringSSL library repository.
set (GIT_REPOSITORY https://github.com/google/boringssl.git)
# Specific version to fetch.
set (GIT_TAG        0.20250212.0)
# Apply KasperskyOS adaptation patch after downloading.
set (GIT_PATCH      ${CMAKE_CURRENT_LIST_DIR}/KasperskyOS-CE-adaptation.patch)
set (PATCH_COMMAND  git apply ${GIT_PATCH})

# Prevent redundant patch application on subsequent builds.
if (BORINGSSL_POPULATED)
    # Library has already been fetched — skip patching to avoid conflicts.
    set (PATCH_COMMAND)
else ()
    message (STATUS "Downloading BoringSSL ${GIT_TAG}")
endif ()

# Declare the external dependency with patch configuration.
FetchContent_Declare (BoringSSL
                      GIT_REPOSITORY ${GIT_REPOSITORY}
                      GIT_TAG        ${GIT_TAG}
                      GIT_SHALLOW    YES
                      PATCH_COMMAND  ${PATCH_COMMAND})

# Execute the download and integration of the BoringSSL library into the build system.
FetchContent_MakeAvailable (BoringSSL)

# Cache the population state to optimize subsequent builds.
set (BORINGSSL_POPULATED ${BoringSSL_POPULATED} CACHE INTERNAL "")

add_library (BoringSSL::SSL ALIAS ssl)
add_library (BoringSSL::Crypto ALIAS crypto)

# Install BoringSSL headers to the standard include directory for dependent projects.
set (PROJECT_NAME BoringSSL)
include (platform/install)
install (DIRECTORY ${BoringSSL_SOURCE_DIR}/include/
         DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
# Export CMake targets to enable find_package() integration for dependent projects.
export_targets (TARGETS ssl crypto
                GENERATE_CONFIG_IN
                NO_SET_AND_CHECK_MACRO)
