# © 2024 AO Kaspersky Lab
# Licensed under the OpenSSL License

project(hasher)

# Include the CMake library named nk for working with the NK compiler (nk-gen-c).
include(platform/nk)

# Set the linker and compiler flags.
project_header_default("STANDARD_GNU_11:YES" "STRICT_WARNINGS:NO")

generate_edl_file(Hasher PREFIX examples)
nk_build_edl_files(hasher_edl_files NK_MODULE examples EDL "${EDL_FILE}")

add_executable(Hasher "${EXAMPLES_ROOT_DIR}/common/src/main.cpp")
add_dependencies(Hasher hasher_edl_files)
target_compile_features(Hasher PRIVATE cxx_std_17)
target_link_libraries(Hasher PRIVATE BoringSSL::crypto)
