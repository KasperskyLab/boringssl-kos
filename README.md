# KasperskyOS adaptation patch for BoringSSL

This project provides an adaptation patch for the
[BoringSSL library](https://github.com/google/boringssl), enabling its use in KasperskyOS-based
solutions. The project is based on the
[0.20250212.0](https://github.com/google/boringssl/tree/0.20250212.0) tag of the BoringSSL library.

For details on BoringSSL—a fork of the OpenSSL library—see its official
[README.md](https://github.com/google/boringssl/blob/master/README.md)

For additional details on KasperskyOS, including its limitations and known issues, please refer to
the [KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.4&customization=KCE&helpid=community_edition).

## Table of contents
- [KasperskyOS adaptation patch for BoringSSL](#kasperskyos-adaptation-patch-for-boringssl)
  - [Table of contents](#table-of-contents)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building and installing](#building-and-installing)
  - [Usage](#usage)
  - [Trademarks](#trademarks)
  - [Contributing](#contributing)
  - [Licensing](#licensing)

## Getting started

### Prerequisites

1. Confirm that your host system meets all the
[System requirements](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.4&customization=KCE&helpid=system_requirements)
listed in the KasperskyOS Community Edition Developer's Guide.
1. [Install](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.4&customization=KCE&helpid=sdk_install_and_remove)
the KasperskyOS Community Edition SDK version 1.4. You can download it for free from
[os.kaspersky.com](https://os.kaspersky.com/development/).
1. Copy the source files of this adaptation patch to your local project directory.
1. Source the SDK setup script to configure the build environment. This exports the `KOSCEDIR`
  environment variable, which points to the SDK installation directory:
   ```sh
   source /opt/KasperskyOS-Community-Edition-<platform>-<version>/common/set_env.sh
   ```

### Building and installing

The KasperskyOS-adapted version of the BoringSSL library is built using the CMake build system,
which is provided in the KasperskyOS Community Edition SDK. When you develop a KasperskyOS-based
solution, use the
[recommended structure of project directories](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.4&customization=KCE&helpid=cmake_using_sdk_cmake)
to simplify usage of CMake scripts.

To install the BoringSSL library adapted for KasperskyOS, run the following command:

```sh
$ cmake -B build -D CMAKE_TOOLCHAIN_FILE="$KOSCEDIR/toolchain/share/toolchain-aarch64-kos.cmake"
$ cmake --build build --target all
$ cmake --install build --prefix "$HOME/.local/share/kos/$(basename $KOSCEDIR)/sysroot-aarch64-kos"
```

> [!WARNING]
> The KasperskyOS Community Edition SDK comes with pre-built OpenSSL library. It is strongly not
recommended to install BoringSSL to the KasperskyOS SDK
`/opt/KasperskyOS-Community-Edition-<platform>-<version>/sysroot-<platform>`
directory, as it will cause OpenSSL to malfunction and render it unusable.

[⬆ Back to Top](#table-of-contents)

## Usage

To integrate the adapted BoringSSL library in a KasperskyOS-based solution, there are three
recommended options: using the library source code as a git submodule, using the previously
installed BoringSSL library, or using the CMake module `FetchContent`. For practical guidance, see
the [BoringSSL example](https://github.com/KasperskyLab/kos-ce-extra/tree/master/examples/boringssl)
in the `KasperskyLab/kos-ce-extra` repository, which demonstrates all three approaches.

## Trademarks

Registered trademarks and endpoint marks are the property of their respective owners.

Apache is either a registered trademark or a trademark of the Apache Software Foundation in the
United States and/or other countries.

Apple, macOS are trademarks of Apple Inc.

Arm is a registered trademark of Arm Limited (or its subsidiaries) in the US and/or elsewhere.

Docker and the Docker logo are trademarks or registered trademarks of Docker, Inc. in the United
States and/or other countries. Docker, Inc. and other parties may also have trademark rights in
other terms used herein.

GITHUB is a trademark of GitHub, Inc., registered in the United States and other countries.

Google is a trademark of Google LLC.

iOS is a registered trademark or trademark of Cisco Systems, Inc. and/or its affiliates in the
United States and certain other countries.

Linux is the registered trademark of Linus Torvalds in the U.S. and other countries.

OpenSSL is a trademark owned by the OpenSSL Software Foundation.

BoringSSL adaptation for KasperskyOS is not affiliated with OpenSSL.

Raspberry Pi is a trademark of the Raspberry Pi Foundation.

Windows is a trademark of the Microsoft group of companies.

## Contributing

Only KasperskyOS-specific changes can be approved. See [CONTRIBUTING.md](CONTRIBUTING.md) for
detailed instructions on code contribution.

## Licensing

This project is licensed under the terms of the MIT license. See [LICENSE](LICENSE) for more information.

This project comprises publication(s) intended to be used with [BoringSSL library](https://github.com/google/boringssl/tree/0.20250212.0) ( “Upstream Project”).
The Upstream Project is licensed and distributed under its own license terms, which are separate from the terms of this project.
Nothing in this repository is intended to modify, replace, supersede, or relicense the Upstream Project or any of its components.

[⬆ Back to Top](#table-of-contents)

© 2026 AO Kaspersky Lab
