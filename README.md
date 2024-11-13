# BoringSSL adaptation for KasperskyOS

This project is an adaptation of the [BoringSSL library](https://github.com/google/boringssl) for KasperskyOS.
The project is based on a [commit](https://github.com/google/boringssl/commit/b9232f9e27e5668bc0414879dcdedb2a59ea75f2) and
includes 3 examples demonstrating the use of the BoringSSL library in KasperskyOS.

BoringSSL library for KasperskyOS is based on the BoringSSL library, a fork of OpenSSL library.
BoringSSL library for KasperskyOS is intended to provide security and encryption in network applications.

For more information about BoringSSL library, see the
[README.md](https://github.com/google/boringssl/blob/master/README.md) file of this library.

For additional details on KasperskyOS, including its limitations and known issues, please refer to the
[KasperskyOS Community Edition Online Help](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_community_edition).

## Table of contents
- [BoringSSL adaptation for KasperskyOS](#boringssl-adaptation-for-kasperskyos)
  - [Table of contents](#table-of-contents)
  - [Getting started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Building and installing](#building-and-installing)
      - [BoringSSL library for KasperskyOS](#boringssl-library-for-kasperskyos)
      - [Tests](#tests)
  - [Usage](#usage)
    - [Examples](#examples)
    - [Tests](#tests-1)
  - [Trademarks](#trademarks)
  - [Contributing](#contributing)
  - [Licensing](#licensing)

## Getting started

### Prerequisites

1. [Install](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_sdk_install_and_remove) KasperskyOS Community Edition SDK. You can download the latest version of the KasperskyOS Community Edition for free from [os.kaspersky.com](https://os.kaspersky.com/development/). The minimum required version of KasperskyOS Community Edition SDK is 1.2. For more information, see [System requirements](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_system_requirements).
1. Copy source files to your project directory. The examples of KasperskyOS-based solutions are located in the following directory:
   ```
   ./kos
   ```
1. To build and run unit tests for BoringSSL library for KasperskyOS, install the `golang` package by running the command:
   ```sh
   apt-get install -y golang
   ```

### Building and installing
#### BoringSSL library for KasperskyOS

The BoringSSL library for KasperskyOS is built using the CMake build system, which is provided in the KasperskyOS Community Edition SDK.

To build and install the BoringSSL library, execute the `cross-build.sh` script located in the `./kos` directory. There are environment variables that affect the build and installation of the BoringSSL library:

* `SDK_PREFIX` specifies the path to the installed version of the KasperskyOS Community Edition SDK. The value of this environment variable must be set.
* `INSTALL_PREFIX` specifies the installation path of the library. If not specified, the library will be installed in the `./kos/install` directory.
* `TARGET` specifies the target platform. (Currently only the `aarch64-kos` platform is supported.)

> [!WARNING]
> The KasperskyOS Community Edition SDK comes with pre-built OpenSSL libraries and headers. It is strongly not recommended to install BoringSSL to the KasperskyOS SDK `sysroot-<platform>` directory, as it will cause OpenSSL to malfunction and render it unusable.

For example, review the following command:
```sh
$ SDK_PREFIX=/opt/KasperskyOS-Community-Edition-<version> INSTALL_PREFIX=/home/libs/BoringSSL-kos ./cross-build.sh
```
The BoringSSL library is built and installed in the `/home/libs/BoringSSL-kos/` directory using the
SDK toolchain found in the `/opt/KasperskyOS-Community-Edition-<version>` path, where `version` is the
latest version number of the KasperskyOS Community Edition SDK.

You can also use the following options instead of or in addition to environment variables:

* `-h, --help`

  Help text.
* `-s, --sdk SDK_PREFIX`

  Path to the installed version of the KasperskyOS Community Edition SDK. The value specified
in the `-s` option takes precedence over the value of the `SDK_PREFIX` environment variable.
* `-i, --install INSTALL_PREFIX`

  Directory where BoringSSL for KasperskyOS binary files are installed. The value specified in
the `-i` option takes precedence over the value of the `INSTALL_PREFIX` environment variable.

For example:
```sh
$ ./cross-build.sh -s /opt/KasperskyOS-Community-Edition-<version> -i /opt/libs
```

[⬆ Back to Top](#Table-of-contents)

#### Tests

The BoringSSL library's [tests](src/third_party/googletest) have been adapted to run on KasperskyOS. The tests have the following limitations:

* Unit tests for KasperskyOS are currently only available for QEMU.
* Only IPv4 tests are compatible with KasperskyOS.
* `RandTest.Fork` test is skipped due to the `fork` system call is not supported by KasperskyOS.

Tests use an out-of-source build. The build tree is situated in the generated `build_tests` subdirectory of the `kos` directory. For each test suite, a separate image will be created. As it can be taxing on disk space, the tests will run sequentially.

There are environment variables that affect the build and installation of the tests:

* `SDK_PREFIX` specifies the path to the installed version of the KasperskyOS Community Edition SDK. The value of this environment variable must be set.
* `TARGET` specifies the target platform. (Currently only the `aarch64-kos` platform is supported.)

To build and run the tests, go to the `./kos` directory and run the command:

`$ [TARGET="aarch64-kos"] ./run-tests.sh [-s SDK_PREFIX] [--help] [--list] [-n TEST_NAME_1] ... [-n TEST_NAME_N] [-t TIMEOUT] [-o OUT_PATH] [-j N_JOBS]`,

where:

* `-s, --sdk SDK_PREFIX`

  Path to the installed version of the KasperskyOS Community Edition SDK. The value specified in the `-s` option takes precedence over the value of the `SDK_PREFIX` environment variable.
* `-h, --help`

  Help text.
* `-l, --list`

  List of tests that can be run.
* `-n, --name TEST_NAME`

  Test name to execute. The parameter can be repeated multiple times. If not specified, all tests will be executed.
* `-t, --timeout TIMEOUT`

  Time, in seconds, allotted to start and execute a single test case. Default value is 300 seconds.
* `-o, --out OUT_PATH`

  Path where the results of the test run will be stored. If not specified, the results will be stored in the `./kos/build_tests/logs` directory.
* `-j, --jobs N_JOBS`

  Number of jobs for parallel build. If not specified, the default value obtained from the `nproc` command is used.

For example, to start executing all tests, use the following command:
```
$ SDK_PREFIX=/opt/KasperskyOS-Community-Edition-<version> ./run-tests.sh
```

[⬆ Back to Top](#Table-of-contents)

## Usage

To include the BoringSSL library in a KasperskyOS-based solution, there are three recommended options: using the library source code as a git submodule, using the previously installed BoringSSL library, or using the CMake module `FetchContent`. Each project example demonstrates one of these methods.

When you develop a KasperskyOS-based solution, use the [recommended structure of project directories](https://click.kaspersky.com/?hl=en-us&link=online_help&pid=kos&version=1.2&customization=KCE_cmake_using_sdk_cmake) to simplify usage of CMake scripts.

### Examples

* [`./kos/examples/common/`](kos/examples/common/)—Common source code for all examples that calculates the SHA256 hash for the `Test Message Hello World` message.
* [`./kos/examples/use_as_submodule/`](kos/examples/use_as_submodule/)—Example of using the BoringSSL library source code as a git submodule.
* [`./kos/examples/use_installed/`](kos/examples/use_installed/)—Example of using the previously installed BoringSSL library.
* [`./kos/examples/use_with_fetch_content/`](kos/examples/use_with_fetch_content/)—Example of using the CMake module `FetchContent`.

### Tests

[`./kos/run-tests.sh`](kos/run-tests.sh)—Script runs unit tests using the GoogleTest framework.

[⬆ Back to Top](#Table-of-contents)

## Trademarks

Registered trademarks and endpoint marks are the property of their respective owners.

GoogleTest is a trademark of Google LLC.

OpenSSL is a trademark owned by the OpenSSL Software Foundation.
BoringSSL adaptation for KasperskyOS is not affiliated with OpenSSL.

Raspberry Pi is a trademark of the Raspberry Pi Foundation.

## Contributing

Only KasperskyOS-specific changes can be approved. See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed instructions on code contribution.

## Licensing

This project is licensed under the terms of the OpenSSL License. See [LICENSE](LICENSE) for more information.

[⬆ Back to Top](#Table-of-contents)

© 2024 AO Kaspersky Lab
