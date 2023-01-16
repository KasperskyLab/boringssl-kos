# BoringSSL adaptation for KasperskyOS

This is a fork of [BoringSSL](https://github.com/google/boringssl) project adapted to be used with KasperskyOS. The modification is based on [b9232f9e](https://github.com/google/boringssl/tree/b9232f9e27e5668bc0414879dcdedb2a59ea75f2) commit. For more information about the target OS, please refer to [KaspeksyOS Community Edition](https://support.kaspersky.com/help/KCE/1.1/en-US/community_edition.htm).

BoringSSL is a fork of OpenSSL that is designed to meet Google's needs.

## About BoringSSL

Although BoringSSL is an open source project, it is not intended for general
use, as OpenSSL is.

BoringSSL arose because Google used OpenSSL for many years in various ways and,
over time, built up a large number of patches that were maintained while
tracking upstream OpenSSL. As Google's product portfolio became more complex,
more copies of OpenSSL sprung up and the effort involved in maintaining all
these patches in multiple places was growing steadily.

Currently BoringSSL is the SSL library in Chrome/Chromium, Android (but it's
not part of the NDK) and a number of other apps/programs.

## Building BoringSSL

For a default build and use, you need to install the KasperskyOS Community Edition SDK on your system. The latest version of the SDK can be downloaded from this [link](https://os.kaspersky.com/development/). The Abseil source code has been checked on the KasperskyOS Community Edition SDK version 1.1.0.

See the [BUILDING.md](https://github.com/google/boringssl/blob/master/BUILDING.md) for more information on building BorinSSL.

## Contributing
Please see the [Contributing](https://github.com/google/boringssl/blob/master/CONTRIBUTING.md) page for generic info.

We'll follow the parent project contributing rules but would consider to accept only KasperskyOS-specific changes, so for that it is advised to use pull-requests.

## License

The BoringSSL library is licensed under the terms of the OpenSSL License. See [LICENSE](LICENSE) for more information.

## Links

  * [API documentation](https://commondatastorage.googleapis.com/chromium-boringssl-docs/headers.html)
  * [PORTING.md](https://github.com/google/boringssl/blob/master/PORTING.md): how to port OpenSSL-using code to BoringSSL.
  * [API-CONVENTIONS.md](https://github.com/google/boringssl/blob/master/API-CONVENTIONS.md): general API conventions for BoringSSL consumers and developers.
  * [STYLE.md](https://github.com/google/boringssl/blob/master/STYLE.md): rules and guidelines for coding style.