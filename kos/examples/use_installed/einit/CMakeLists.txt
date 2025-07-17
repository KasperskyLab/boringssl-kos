# © 2025 AO Kaspersky Lab
# Licensed under the OpenSSL License

project(einit)

# Include the CMake library named image,
# which contains the solution image build scripts.
include(platform/image)
include(${KL_SDK_ROOT_PATH}/common/build-sd-image.cmake)

# Set the linker and compiler flags.
project_header_default("STANDARD_GNU_17:YES" "STRICT_WARNINGS:NO")

# Set the values of the variables.
set(ENTITIES Hasher)
set(SECURITY_PSL_FILE "src/security.psl.in")
set(CONNECTIONS_CFG_FILE "src/init.yaml.in")
set(QEMU_FLAGS "-nographic -monitor none -nic none")

# Create a top-level CMake target named kos-image which can be used
# when building a solution image to be started on the hardware platform.
build_kos_hw_image(kos-image
  EINIT_ENTITY EinitHw
  CONNECTIONS_CFG ${CONNECTIONS_CFG_FILE}
  SECURITY_PSL ${SECURITY_PSL_FILE}
  ${ENTITIES}
)

# Create a top-level CMake target named sd-image which can be used
# when building an SD card image to be started on the hardware platform.
build_sd_image(sd-image KOS_IMAGE_TARGET kos-image)

# Create a top-level CMake target named kos-qemu-image which
# can be used when building a solution image to be started in QEMU.
build_kos_qemu_image(kos-qemu-image
  EINIT_ENTITY EinitQemu
  QEMU_FLAGS "${QEMU_FLAGS}"
  CONNECTIONS_CFG ${CONNECTIONS_CFG_FILE}
  SECURITY_PSL ${SECURITY_PSL_FILE}
  ${ENTITIES}
)

#set_target_properties(EinitQemu PROPERTIES LINK_FLAGS "-no-pie -Ttext 0x00200000")
