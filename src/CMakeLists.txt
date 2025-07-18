# © 2025 AO Kaspersky Lab
# Licensed under the OpenSSL License

cmake_minimum_required(VERSION 3.5)

# Defer enabling C and CXX languages.
project(BoringSSL NONE)

if(WIN32)
  # On Windows, prefer cl over gcc if both are available. By default most of
  # the CMake generators prefer gcc, even on Windows.
  set(CMAKE_GENERATOR_CC cl)
endif()

include(sources.cmake)

enable_language(C)
enable_language(CXX)

if(KOS)
  include(${KOS_DIR}/cmake/tests.cmake)
endif()

# This is a dummy target which all other targets depend on (manually - see other
# CMakeLists.txt files). This gives us a hook to add any targets which need to
# run before all other targets.
add_custom_target(global_target)

if(ANDROID)
  # Android-NDK CMake files reconfigure the path and so Go and Perl won't be
  # found. However, ninja will still find them in $PATH if we just name them.
  if(NOT PERL_EXECUTABLE)
    set(PERL_EXECUTABLE "perl")
  endif()
  if(NOT GO_EXECUTABLE)
    set(GO_EXECUTABLE "go")
  endif()
else()
  find_package(Perl REQUIRED)
  find_program(GO_EXECUTABLE go)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND NOT CMAKE_CROSSCOMPILING)
  find_package(PkgConfig QUIET)
  if (PkgConfig_FOUND)
    pkg_check_modules(LIBUNWIND libunwind-generic)
    if(LIBUNWIND_FOUND)
      add_definitions(-DBORINGSSL_HAVE_LIBUNWIND)
    else()
      message("libunwind not found. Disabling unwind tests.")
    endif()
  else()
    message("pkgconfig not found. Disabling unwind tests.")
  endif()
endif()

if(NOT GO_EXECUTABLE)
  message(FATAL_ERROR "Could not find Go")
endif()

if(USE_CUSTOM_LIBCXX)
  set(BORINGSSL_ALLOW_CXX_RUNTIME 1)
endif()

if(BORINGSSL_ALLOW_CXX_RUNTIME)
  add_definitions(-DBORINGSSL_ALLOW_CXX_RUNTIME)
endif()

string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_LOWER)
if(NOT FIPS)
  if(CMAKE_BUILD_TYPE_LOWER STREQUAL "relwithassert" OR
     NOT CMAKE_BUILD_TYPE_LOWER MATCHES "rel")
    add_definitions(-DBORINGSSL_DISPATCH_TEST)
    # CMake automatically connects include_directories to the NASM
    # command-line, but not add_definitions.
    set(CMAKE_ASM_NASM_FLAGS "${CMAKE_ASM_NASM_FLAGS} -DBORINGSSL_DISPATCH_TEST")
  endif()
endif()

# Add a RelWithAsserts build configuration. It is the same as Release, except it
# does not define NDEBUG, so asserts run.
foreach(VAR CMAKE_C_FLAGS CMAKE_CXX_FLAGS CMAKE_ASM_FLAGS)
  string(REGEX REPLACE "(^| )[/-]DNDEBUG( |$)" " " "${VAR}_RELWITHASSERTS"
         "${${VAR}_RELEASE}")
endforeach()

if(BORINGSSL_PREFIX AND BORINGSSL_PREFIX_SYMBOLS)
  add_definitions(-DBORINGSSL_PREFIX=${BORINGSSL_PREFIX})
  # CMake automatically connects include_directories to the NASM command-line,
  # but not add_definitions.
  set(CMAKE_ASM_NASM_FLAGS "${CMAKE_ASM_NASM_FLAGS} -DBORINGSSL_PREFIX=${BORINGSSL_PREFIX}")

  # Use "symbol_prefix_include" to store generated header files
  include_directories(${CMAKE_CURRENT_BINARY_DIR}/symbol_prefix_include)
  add_custom_command(
    OUTPUT symbol_prefix_include/boringssl_prefix_symbols.h
           symbol_prefix_include/boringssl_prefix_symbols_asm.h
           symbol_prefix_include/boringssl_prefix_symbols_nasm.inc
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/symbol_prefix_include
    COMMAND ${GO_EXECUTABLE} run ${CMAKE_CURRENT_SOURCE_DIR}/util/make_prefix_headers.go -out ${CMAKE_CURRENT_BINARY_DIR}/symbol_prefix_include ${BORINGSSL_PREFIX_SYMBOLS}
    DEPENDS util/make_prefix_headers.go
            ${CMAKE_BINARY_DIR}/${BORINGSSL_PREFIX_SYMBOLS})

  # add_dependencies needs a target, not a file, so we add an intermediate
  # target.
  add_custom_target(
    boringssl_prefix_symbols
    DEPENDS symbol_prefix_include/boringssl_prefix_symbols.h
            symbol_prefix_include/boringssl_prefix_symbols_asm.h
            symbol_prefix_include/boringssl_prefix_symbols_nasm.inc)
  add_dependencies(global_target boringssl_prefix_symbols)
elseif(BORINGSSL_PREFIX OR BORINGSSL_PREFIX_SYMBOLS)
  message(FATAL_ERROR "Must specify both or neither of BORINGSSL_PREFIX and BORINGSSL_PREFIX_SYMBOLS")
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  set(CLANG 1)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
  set(EMSCRIPTEN 1)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CLANG)
  # Note clang-cl is odd and sets both CLANG and MSVC. We base our configuration
  # primarily on our normal Clang one.
  set(C_CXX_FLAGS "-Werror -Wformat=2 -Wsign-compare -Wmissing-field-initializers -Wwrite-strings -Wvla -Wshadow")
  if(MSVC)
    # clang-cl sets different default warnings than clang. It also treats -Wall
    # as -Weverything, to match MSVC. Instead -W3 is the alias for -Wall.
    # See http://llvm.org/viewvc/llvm-project?view=revision&revision=319116
    set(C_CXX_FLAGS "${C_CXX_FLAGS} -W3 -Wno-unused-parameter -fmsc-version=1900")
    # googletest suppresses warning C4996 via a pragma, but clang-cl does not
    # honor it. Suppress it here to compensate. See https://crbug.com/772117.
    set(C_CXX_FLAGS "${C_CXX_FLAGS} -Wno-deprecated-declarations")
  else()
    if(EMSCRIPTEN)
      # emscripten's emcc/clang does not accept the "-ggdb" flag.
      set(C_CXX_FLAGS "${C_CXX_FLAGS} -g")
    else()
      set(C_CXX_FLAGS "${C_CXX_FLAGS} -ggdb")
    endif()

    set(C_CXX_FLAGS "${C_CXX_FLAGS} -Wall -fvisibility=hidden -fno-common")
  endif()

  if(CLANG)
    set(C_CXX_FLAGS "${C_CXX_FLAGS} -Wnewline-eof -fcolor-diagnostics")
  else()
    # GCC (at least 4.8.4) has a bug where it'll find unreachable free() calls
    # and declare that the code is trying to free a stack pointer.
    set(C_CXX_FLAGS "${C_CXX_FLAGS} -Wno-free-nonheap-object")
  endif()

  if(CLANG OR NOT "7.0.0" VERSION_GREATER CMAKE_C_COMPILER_VERSION)
    set(C_CXX_FLAGS "${C_CXX_FLAGS} -Wimplicit-fallthrough")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${C_CXX_FLAGS} -Wmissing-prototypes -Wold-style-definition -Wstrict-prototypes")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${C_CXX_FLAGS} -Wmissing-declarations")

  if(NOT MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
    if(APPLE)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
    endif()
    if(NOT BORINGSSL_ALLOW_CXX_RUNTIME)
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions -fno-rtti")
    endif()
  endif()

  # In GCC, -Wmissing-declarations is the C++ spelling of -Wmissing-prototypes
  # and using the wrong one is an error. In Clang, -Wmissing-prototypes is the
  # spelling for both and -Wmissing-declarations is some other warning.
  #
  # https://gcc.gnu.org/onlinedocs/gcc-7.1.0/gcc/Warning-Options.html#Warning-Options
  # https://clang.llvm.org/docs/DiagnosticsReference.html#wmissing-prototypes
  # https://clang.llvm.org/docs/DiagnosticsReference.html#wmissing-declarations
  if(CLANG)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wmissing-prototypes")
  endif()
elseif(MSVC)
  set(MSVC_DISABLED_WARNINGS_LIST
      "C4061" # enumerator 'identifier' in switch of enum 'enumeration' is not
              # explicitly handled by a case label
              # Disable this because it flags even when there is a default.
      "C4100" # 'exarg' : unreferenced formal parameter
      "C4127" # conditional expression is constant
      "C4200" # nonstandard extension used : zero-sized array in
              # struct/union.
      "C4204" # nonstandard extension used: non-constant aggregate initializer
      "C4221" # nonstandard extension used : 'identifier' : cannot be
              # initialized using address of automatic variable
      "C4242" # 'function' : conversion from 'int' to 'uint8_t',
              # possible loss of data
      "C4244" # 'function' : conversion from 'int' to 'uint8_t',
              # possible loss of data
      "C4267" # conversion from 'size_t' to 'int', possible loss of data
      "C4371" # layout of class may have changed from a previous version of the
              # compiler due to better packing of member '...'
      "C4388" # signed/unsigned mismatch
      "C4296" # '>=' : expression is always true
      "C4350" # behavior change: 'std::_Wrap_alloc...'
      "C4365" # '=' : conversion from 'size_t' to 'int',
              # signed/unsigned mismatch
      "C4389" # '!=' : signed/unsigned mismatch
      "C4464" # relative include path contains '..'
      "C4510" # 'argument' : default constructor could not be generated
      "C4512" # 'argument' : assignment operator could not be generated
      "C4514" # 'function': unreferenced inline function has been removed
      "C4548" # expression before comma has no effect; expected expression with
              # side-effect" caused by FD_* macros.
      "C4610" # struct 'argument' can never be instantiated - user defined
              # constructor required.
      "C4623" # default constructor was implicitly defined as deleted
      "C4625" # copy constructor could not be generated because a base class
              # copy constructor is inaccessible or deleted
      "C4626" # assignment operator could not be generated because a base class
              # assignment operator is inaccessible or deleted
      "C4628" # digraphs not supported with -Ze
      "C4668" # 'symbol' is not defined as a preprocessor macro, replacing with
              # '0' for 'directives'
              # Disable this because GTest uses it everywhere.
      "C4706" # assignment within conditional expression
      "C4710" # 'function': function not inlined
      "C4711" # function 'function' selected for inline expansion
      "C4800" # 'int' : forcing value to bool 'true' or 'false'
              # (performance warning)
      "C4820" # 'bytes' bytes padding added after construct 'member_name'
      "C5026" # move constructor was implicitly defined as deleted
      "C5027" # move assignment operator was implicitly defined as deleted
      "C5045" # Compiler will insert Spectre mitigation for memory load if
              # /Qspectre switch specified
      )
  set(MSVC_LEVEL4_WARNINGS_LIST
      # See https://connect.microsoft.com/VisualStudio/feedback/details/1217660/warning-c4265-when-using-functional-header
      "C4265" # class has virtual functions, but destructor is not virtual
      )
  string(REPLACE "C" " -wd" MSVC_DISABLED_WARNINGS_STR
                            ${MSVC_DISABLED_WARNINGS_LIST})
  string(REPLACE "C" " -w4" MSVC_LEVEL4_WARNINGS_STR
                            ${MSVC_LEVEL4_WARNINGS_LIST})
  set(CMAKE_C_FLAGS   "-utf-8 -Wall -WX ${MSVC_DISABLED_WARNINGS_STR} ${MSVC_LEVEL4_WARNINGS_STR}")
  set(CMAKE_CXX_FLAGS "-utf-8 -Wall -WX ${MSVC_DISABLED_WARNINGS_STR} ${MSVC_LEVEL4_WARNINGS_STR}")
endif()

if(WIN32)
  add_definitions(-D_HAS_EXCEPTIONS=0)
  add_definitions(-DWIN32_LEAN_AND_MEAN)
  add_definitions(-DNOMINMAX)
  # Allow use of fopen.
  add_definitions(-D_CRT_SECURE_NO_WARNINGS)
  # VS 2017 and higher supports STL-only warning suppressions.
  # A bug in CMake < 3.13.0 may cause the space in this value to
  # cause issues when building with NASM. In that case, update CMake.
  add_definitions("-D_STL_EXTRA_DISABLED_WARNINGS=4774 4987")
endif()

if(CMAKE_COMPILER_IS_GNUCXX)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c11")
endif()

# pthread_rwlock_t requires a feature flag.
if(NOT WIN32)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_XOPEN_SOURCE=700")
endif()

if(FUZZ)
  if(NOT CLANG)
    message(FATAL_ERROR "You need to build with Clang for fuzzing to work")
  endif()

  if(CMAKE_C_COMPILER_VERSION VERSION_LESS "6.0.0")
    message(FATAL_ERROR "You need Clang ≥ 6.0.0")
  endif()

  add_definitions(-DBORINGSSL_UNSAFE_DETERMINISTIC_MODE)
  set(RUNNER_ARGS "-deterministic")

  if(NOT NO_FUZZER_MODE)
    add_definitions(-DBORINGSSL_UNSAFE_FUZZER_MODE)
    set(RUNNER_ARGS ${RUNNER_ARGS} "-fuzzer" "-shim-config" "fuzzer_mode.json")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=address,fuzzer-no-link -fsanitize-coverage=edge,indirect-calls")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address,fuzzer-no-link -fsanitize-coverage=edge,indirect-calls")
endif()

add_definitions(-DBORINGSSL_IMPLEMENTATION)

if(BUILD_SHARED_LIBS)
  add_definitions(-DBORINGSSL_SHARED_LIBRARY)
  # Enable position-independent code globally. This is needed because
  # some library targets are OBJECT libraries.
  set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
endif()

if(MSAN)
  if(NOT CLANG)
    message(FATAL_ERROR "Cannot enable MSAN unless using Clang")
  endif()

  if(ASAN)
    message(FATAL_ERROR "ASAN and MSAN are mutually exclusive")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=memory -fsanitize-memory-track-origins -fno-omit-frame-pointer")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=memory -fsanitize-memory-track-origins -fno-omit-frame-pointer")
  set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -fsanitize=memory -fsanitize-memory-track-origins -fno-omit-frame-pointer")
endif()

if(ASAN)
  if(NOT CLANG)
    message(FATAL_ERROR "Cannot enable ASAN unless using Clang")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=address -fsanitize-address-use-after-scope -fno-omit-frame-pointer")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fsanitize-address-use-after-scope -fno-omit-frame-pointer")
endif()

if(CFI)
  if(NOT CLANG)
    message(FATAL_ERROR "Cannot enable CFI unless using Clang")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=cfi -fno-sanitize-trap=cfi -flto=thin")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=cfi -fno-sanitize-trap=cfi -flto=thin")
  # We use Chromium's copy of clang, which requires -fuse-ld=lld if building
  # with -flto. That, in turn, can't handle -ggdb.
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=lld")
  string(REPLACE "-ggdb" "-g" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
  string(REPLACE "-ggdb" "-g" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  # -flto causes object files to contain LLVM bitcode. Mixing those with
  # assembly output in the same static library breaks the linker.
  set(OPENSSL_NO_ASM "1")
endif()

if(TSAN)
  if(NOT CLANG)
    message(FATAL_ERROR "Cannot enable TSAN unless using Clang")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=thread")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=thread")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=thread")
endif()

if(UBSAN)
  if(NOT CLANG)
    message(FATAL_ERROR "Cannot enable UBSAN unless using Clang")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=undefined")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=undefined")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=undefined")

  if(NOT UBSAN_RECOVER)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-sanitize-recover=undefined")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-sanitize-recover=undefined")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fno-sanitize-recover=undefined")
  endif()
endif()

if(GCOV)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-arcs -ftest-coverage")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs -ftest-coverage")
endif()

if(FIPS)
  add_definitions(-DBORINGSSL_FIPS)
  if(FIPS_BREAK_TEST)
    add_definitions("-DBORINGSSL_FIPS_BREAK_${FIPS_BREAK_TEST}=1")
  endif()
  # The FIPS integrity check does not work for ASan and MSan builds.
  if(NOT ASAN AND NOT MSAN)
    if(BUILD_SHARED_LIBS)
      set(FIPS_SHARED "1")
    else()
      set(FIPS_DELOCATE "1")
    endif()
  endif()
  if(FIPS_SHARED)
    # The Android CMake files set -ffunction-sections and -fdata-sections,
    # which is incompatible with FIPS_SHARED.
    set(CMAKE_C_FLAGS
        "${CMAKE_C_FLAGS} -fno-function-sections -fno-data-sections")
    set(CMAKE_CXX_FLAGS
        "${CMAKE_CXX_FLAGS} -fno-function-sections -fno-data-sections")
  endif()
endif()

if(OPENSSL_SMALL)
  add_definitions(-DOPENSSL_SMALL)
endif()

if(CONSTANT_TIME_VALIDATION)
  add_definitions(-DBORINGSSL_CONSTANT_TIME_VALIDATION)
  # Asserts will often test secret data.
  add_definitions(-DNDEBUG)
endif()

function(go_executable dest package)
  set(godeps "${CMAKE_SOURCE_DIR}/util/godeps.go")
  if(CMAKE_VERSION VERSION_LESS "3.7" OR NOT CMAKE_GENERATOR STREQUAL "Ninja")
    # The DEPFILE parameter to add_custom_command is new as of CMake 3.7 and
    # only works with Ninja. Query the sources at configure time. Additionally,
    # everything depends on go.mod. That affects what external packages to use.
    execute_process(COMMAND ${GO_EXECUTABLE} run ${godeps} -format cmake
                            -pkg ${package}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    OUTPUT_VARIABLE sources
                    RESULT_VARIABLE godeps_result)
    add_custom_command(OUTPUT ${dest}
                       COMMAND ${GO_EXECUTABLE} build
                               -o ${CMAKE_CURRENT_BINARY_DIR}/${dest} ${package}
                       WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                       DEPENDS ${sources} ${CMAKE_SOURCE_DIR}/go.mod)
  else()
    # Ninja expects the target in the depfile to match the output. This is a
    # relative path from the build directory.
    string(LENGTH "${CMAKE_BINARY_DIR}" root_dir_length)
    math(EXPR root_dir_length "${root_dir_length} + 1")
    string(SUBSTRING "${CMAKE_CURRENT_BINARY_DIR}" ${root_dir_length} -1 target)
    set(target "${target}/${dest}")

    set(depfile "${CMAKE_CURRENT_BINARY_DIR}/${dest}.d")
    add_custom_command(OUTPUT ${dest}
                       COMMAND ${GO_EXECUTABLE} build
                               -o ${CMAKE_CURRENT_BINARY_DIR}/${dest} ${package}
                       COMMAND ${GO_EXECUTABLE} run ${godeps} -format depfile
                               -target ${target} -pkg ${package} -out ${depfile}
                       WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                       DEPENDS ${godeps} ${CMAKE_SOURCE_DIR}/go.mod
                       DEPFILE ${depfile})
  endif()
endfunction()

# CMake's iOS support uses Apple's multiple-architecture toolchain. It takes an
# architecture list from CMAKE_OSX_ARCHITECTURES, leaves CMAKE_SYSTEM_PROCESSOR
# alone, and expects all architecture-specific logic to be conditioned within
# the source files rather than the build. This does not work for our assembly
# files, so we fix CMAKE_SYSTEM_PROCESSOR and only support single-architecture
# builds.
if(NOT OPENSSL_NO_ASM AND CMAKE_OSX_ARCHITECTURES)
  list(LENGTH CMAKE_OSX_ARCHITECTURES NUM_ARCHES)
  if(NOT NUM_ARCHES EQUAL 1)
    message(FATAL_ERROR "Universal binaries not supported.")
  endif()
  list(GET CMAKE_OSX_ARCHITECTURES 0 CMAKE_SYSTEM_PROCESSOR)
endif()

if(OPENSSL_NO_SSE2_FOR_TESTING)
  add_definitions(-DOPENSSL_NO_SSE2_FOR_TESTING)
endif()

if(OPENSSL_NO_ASM)
  add_definitions(-DOPENSSL_NO_ASM)
  set(ARCH "generic")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
  set(ARCH "x86_64")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "amd64")
  set(ARCH "x86_64")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64")
  # cmake reports AMD64 on Windows, but we might be building for 32-bit.
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(ARCH "x86_64")
  else()
    set(ARCH "x86")
  endif()
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86")
  set(ARCH "x86")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "i386")
  set(ARCH "x86")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "i686")
  set(ARCH "x86")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
  set(ARCH "aarch64")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "ARM64")
  set(ARCH "aarch64")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
  set(ARCH "aarch64")
# Apple A12 Bionic chipset which is added in iPhone XS/XS Max/XR uses arm64e architecture.
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64e")
  set(ARCH "aarch64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^arm*")
  set(ARCH "arm")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "mips")
  # Just to avoid the “unknown processor” error.
  set(ARCH "generic")
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "ppc64le")
  set(ARCH "ppc64le")
else()
  message(FATAL_ERROR "Unknown processor:" ${CMAKE_SYSTEM_PROCESSOR})
endif()

if(ANDROID AND NOT ANDROID_NDK_REVISION AND ARCH STREQUAL "arm")
  # The third-party Android-NDK CMake files somehow fail to set the -march flag
  # for assembly files. Without this flag, the compiler believes that it's
  # building for ARMv5.
  set(CMAKE_ASM_FLAGS "-march=${CMAKE_SYSTEM_PROCESSOR} ${CMAKE_ASM_FLAGS}")
endif()

if(USE_CUSTOM_LIBCXX)
  if(NOT CLANG)
    message(FATAL_ERROR "USE_CUSTOM_LIBCXX only supported with Clang")
  endif()

  # CMAKE_CXX_FLAGS ends up in the linker flags as well, so use
  # add_compile_options. There does not appear to be a way to set
  # language-specific compile-only flags.
  add_compile_options("-nostdinc++")
  set(CMAKE_CXX_LINK_FLAGS "${CMAKE_CXX_LINK_FLAGS} -nostdlib++")
  include_directories(
    SYSTEM
    util/bot/libcxx-config
    util/bot/libcxx/include
    util/bot/libcxxabi/include
  )

  # This is patterned after buildtools/third_party/libc++/BUILD.gn and
  # buildtools/third_party/libc++abi/BUILD.gn in Chromium.

  file(GLOB LIBCXX_SOURCES "util/bot/libcxx/src/*.cpp")
  file(GLOB LIBCXXABI_SOURCES "util/bot/libcxxabi/src/*.cpp")

  # This file is meant for exception-less builds.
  list(REMOVE_ITEM LIBCXXABI_SOURCES "trunk/src/cxa_noexception.cpp")
  # libc++ also defines new and delete.
  list(REMOVE_ITEM LIBCXXABI_SOURCES "trunk/src/stdlib_new_delete.cpp")
  if(TSAN)
    # ThreadSanitizer tries to intercept these symbols. Skip them to avoid
    # symbol conflicts.
    list(REMOVE_ITEM LIBCXXABI_SOURCES "trunk/src/cxa_guard.cpp")
  endif()

  add_library(libcxxabi ${LIBCXXABI_SOURCES})
  target_compile_definitions(
    libcxxabi PRIVATE
    -D_LIBCPP_ENABLE_CXX17_REMOVED_UNEXPECTED_FUNCTIONS
  )
  set_target_properties(libcxxabi PROPERTIES COMPILE_FLAGS "-Wno-missing-prototypes -Wno-implicit-fallthrough")
  # libc++abi depends on libc++ internal headers.
  set_property(TARGET libcxxabi APPEND PROPERTY INCLUDE_DIRECTORIES "${CMAKE_SOURCE_DIR}/util/bot/libcxx/src")

  add_library(libcxx ${LIBCXX_SOURCES})
  if(ASAN OR MSAN OR TSAN)
    # Sanitizers try to intercept new and delete.
    target_compile_definitions(
      libcxx PRIVATE
      -D_LIBCPP_DISABLE_NEW_DELETE_DEFINITIONS
    )
  endif()
  target_compile_definitions(
    libcxx PRIVATE
    -D_LIBCPP_BUILDING_LIBRARY
    -DLIBCXX_BUILDING_LIBCXXABI
  )
  target_link_libraries(libcxx libcxxabi)
endif()

# Add minimal googletest targets. The provided one has many side-effects, and
# googletest has a very straightforward build.
add_library(boringssl_gtest third_party/googletest/src/gtest-all.cc)
target_include_directories(boringssl_gtest PRIVATE third_party/googletest)

include_directories(third_party/googletest/include)

# Declare a dummy target to build all unit tests. Test targets should inject
# themselves as dependencies next to the target definition.
add_custom_target(all_tests)

# On Windows, CRYPTO_TEST_DATA is too long to fit in command-line limits.
# TODO(davidben): CMake 3.12 has a list(JOIN) command. Use that when we've
# updated the minimum version.
set(EMBED_TEST_DATA_ARGS "")
foreach(arg ${CRYPTO_TEST_DATA})
  set(EMBED_TEST_DATA_ARGS "${EMBED_TEST_DATA_ARGS}${arg}\n")
endforeach()
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/embed_test_data_args.txt"
     "${EMBED_TEST_DATA_ARGS}")

add_custom_command(
  OUTPUT crypto_test_data.cc
  COMMAND ${GO_EXECUTABLE} run util/embed_test_data.go -file-list
          "${CMAKE_CURRENT_BINARY_DIR}/embed_test_data_args.txt" >
          "${CMAKE_CURRENT_BINARY_DIR}/crypto_test_data.cc"
  DEPENDS util/embed_test_data.go ${CRYPTO_TEST_DATA}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

add_library(crypto_test_data OBJECT crypto_test_data.cc)

add_subdirectory(crypto)
add_subdirectory(ssl)
add_subdirectory(ssl/test)
add_subdirectory(tool)
add_subdirectory(util/fipstools/cavp)
add_subdirectory(util/fipstools/acvp/modulewrapper)
add_subdirectory(decrepit)

if(FUZZ)
  if(LIBFUZZER_FROM_DEPS)
    file(GLOB LIBFUZZER_SOURCES "util/bot/libFuzzer/*.cpp")
    add_library(Fuzzer STATIC ${LIBFUZZER_SOURCES})
    # libFuzzer does not pass our aggressive warnings. It also must be built
    # without -fsanitize-coverage options or clang crashes.
    set_target_properties(Fuzzer PROPERTIES COMPILE_FLAGS "-Wno-shadow -Wno-format-nonliteral -Wno-missing-prototypes -fsanitize-coverage=0")
  endif()

  add_subdirectory(fuzz)
endif()

if(UNIX AND NOT APPLE AND NOT ANDROID)
  set(HANDSHAKER_ARGS "-handshaker-path" $<TARGET_FILE:handshaker>)
endif()

if(FIPS)
  add_custom_target(
    acvp_tests
    COMMAND ${GO_EXECUTABLE} build -o ${CMAKE_BINARY_DIR}/acvptool
            boringssl.googlesource.com/boringssl/util/fipstools/acvp/acvptool
    COMMAND ${GO_EXECUTABLE} build -o ${CMAKE_BINARY_DIR}/testmodulewrapper
            boringssl.googlesource.com/boringssl/util/fipstools/acvp/acvptool/testmodulewrapper
    COMMAND cd util/fipstools/acvp/acvptool/test &&
            ${GO_EXECUTABLE} run check_expected.go
            -tool ${CMAKE_BINARY_DIR}/acvptool
            -module-wrappers modulewrapper:$<TARGET_FILE:modulewrapper>,testmodulewrapper:${CMAKE_BINARY_DIR}/testmodulewrapper
            -tests tests.json
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS modulewrapper
    USES_TERMINAL)

  add_custom_target(
    fips_specific_tests_if_any
    DEPENDS acvp_tests
  )
else()
  add_custom_target(fips_specific_tests_if_any)
endif()

add_custom_target(
    run_tests
    COMMAND ${GO_EXECUTABLE} run util/all_tests.go -build-dir
            ${CMAKE_BINARY_DIR}
    COMMAND cd ssl/test/runner &&
            ${GO_EXECUTABLE} test -shim-path $<TARGET_FILE:bssl_shim>
              ${HANDSHAKER_ARGS} ${RUNNER_ARGS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS all_tests bssl_shim handshaker fips_specific_tests_if_any
    USES_TERMINAL)
