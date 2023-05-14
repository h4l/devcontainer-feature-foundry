# syntax=docker/dockerfile:1
ARG DEBIAN_VERSION_NAME=bullseye
ARG SOLC_VERSION
ARG Z3_VERSION

# To keep builds as quick as possible we always compile on the native platform.
# To build for non-native CPU architectures we explicitly cross-compile, rather
# than emulate the target CPU, because emulation is very slow.
FROM --platform=$BUILDPLATFORM debian:${DEBIAN_VERSION_NAME:?} AS build-host
ARG TARGETARCH
ARG DEBIAN_VERSION_NAME
SHELL ["bash", "-xeuo", "pipefail", "-c"]
WORKDIR /build
RUN apt-get update && apt-get install --no-install-recommends -y \
    # To cross-compile we need the compiler toolchain for the platform we're
    # targeting.
    "crossbuild-essential-${TARGETARCH:?}" \
    # envsubst
    gettext-base \
    # General tools we need to build solc and z3
    cmake git python3

COPY <<-"EOT" cross-config.cmake.template
    # the name of the target operating system
    set(CMAKE_SYSTEM_NAME Linux)

    # which compilers to use for C and C++
    set(CMAKE_C_COMPILER   ${TOOLCHAIN_PREFIX}-linux-gnu-gcc)
    set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}-linux-gnu-g++)

    # where is the target environment located
    set(CMAKE_FIND_ROOT_PATH  /build/solc-build-deps /build/z3)

    # adjust the default behaviour of the FIND_XXX() commands:
    # search programs in the host environment
    set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

    # search headers and libraries in the target environment
    set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOT

RUN echo -n "$(( $(grep -c ^processor /proc/cpuinfo) * 2/3 ))" > /run/make_job_count

# The cross-compile tools use a different naming convention for platforms...
RUN bash -c "declare -A TOOLCHAIN_PREFIXES=([amd64]=x86_64 [arm64]=aarch64) \
    && echo -n \${TOOLCHAIN_PREFIXES[${TARGETARCH:?}]:?} \
        > /run/target_toolchain_prefix"

# We need to configure CMake to use the cross-compiler toolchain instead of the
# native compiler, and tell it where to find target platform dependencies.
RUN TOOLCHAIN_PREFIX=$(cat /run/target_toolchain_prefix) envsubst \
    < ./cross-config.cmake.template > cross-config.cmake


FROM build-host AS z3-build
# The source dir needs to be writable because cmake writes into it
RUN --mount=from=z3-src,source=/,target=/build/z3-src,readwrite \
    mkdir z3-build \
    && cd z3-build \
    && cmake \
        -DCMAKE_INSTALL_PREFIX=/build/z3 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=/build/cross-config.cmake \
        ../z3-src \
    && make -j "$(cat /run/make_job_count)" \
    && make install
RUN "$(cat /run/target_toolchain_prefix)-linux-gnu-strip" ./z3/lib/libz3.so


FROM z3-build AS z3-build-libs
RUN LIB_DIR=/build/z3-libs-debian/usr/lib/$(cat /run/target_toolchain_prefix)-linux-gnu \
    && mkdir -p "${LIB_DIR:?}" /build/z3-versioned-lib-only \
    && cp -a /build/z3/lib/libz3.so* "${LIB_DIR:?}" \
    # Just the major.minor lib file. This is the file that solc actually
    # references. It simplifies things to only ship this file rather than one
    # file and a few symlink aliases of it.
    && find /build/z3/lib/ \
        -regextype egrep -regex '.*\/libz3\.so\.[0-9]+.[0-9]+$' \
        -exec cp {} /build/z3-versioned-lib-only \;


# We need to install the build dependencies of solc for the target platform, not
# the host platform, so we can't just `apt-get install ...` when installing the
# other build tools. Normally when cross-compiling we might use debootstrap to
# install an os tree with dependencies for the target platform's architecture.
# But with Docker Buildx we can achieve that by installing the dependencies in a
# build stage using the target platform. We'll bind-mount this stage's files
# into the build stage when we perform the build.
FROM --platform=${TARGETPLATFORM} debian:${DEBIAN_VERSION_NAME:?} AS solc-build-deps
RUN apt-get update && apt-get install --no-install-recommends -y \
    libboost-all-dev libjsoncpp-dev


FROM build-host AS solc-build
# The source dir needs to be writable because cmake writes into it
RUN --mount=from=solc-src,source=/,target=/build/solc-src,readwrite \
    # Attach solc's target architecture build dependencies
    --mount=from=solc-build-deps,source=/,target=/build/solc-build-deps \
    # Attach the z3 build
    --mount=from=z3-build,source=/build/z3,target=/build/z3 \
    mkdir solc-build \
    && cd solc-build \
    && ( \
        tag=$(git -C /build/solc-src describe --tags --exact-match 2>/dev/null) \
        # an empty prerelease.txt file marks the build as stable release
        && touch /build/solc-src/prerelease.txt \
        && echo "Building stable release from tag: $tag" \
    ) || echo "Building pre-release from untagged commit:" \
              "$(git -C /build/solc-src rev-parse HEAD)" \
    # For reference, this is how release builds are currently done in the solc
    # repo: https://github.com/ethereum/solidity/blob/0a0c389541c0f247691951edd64451be7145436c/.circleci/config.yml#L896
    # We'll do the same, i.e. static build with support for dynamically-loading
    # Z3 if it's available.
    && cmake ../solc-src \
        -DCMAKE_TOOLCHAIN_FILE=/build/cross-config.cmake \
        -DUSE_Z3_DLOPEN=ON -DUSE_CVC4=OFF -DSOLC_STATIC_STDLIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        # By default all warnings are errors. The build instructions say we can
        # disable pedantic mode when not changing the source. Without disabling
        # it, the build fails with warnings from the z3 library.
        # https://docs.soliditylang.org/en/latest/installing-solidity.html#building-from-source
        -DPEDANTIC=OFF \
        # Tests take too long to run in an emulated environment
        -DTESTS=0 \
    && make -j "$(cat /run/make_job_count)"
RUN "$(cat /run/target_toolchain_prefix)-linux-gnu-strip" ./solc-build/solc/solc


FROM alpine AS binaries-metadata
ARG SOLC_VERSION
ARG Z3_VERSION
ARG TARGETARCH
RUN apk add jq
RUN jq --null-input \
       --arg architecture "${TARGETARCH:?}" \
       --arg solc_version "${SOLC_VERSION:?}" \
       --arg z3_version "${Z3_VERSION:?}" \
'{ \
    "$manifest": { \
        "org.opencontainers.image.description": "Solidity Compiler & Z3 library ORAS artifacts", \
        "com.github.h4l.devcontainer-features.solc.architecture": $architecture, \
        "com.github.h4l.devcontainer-features.solc.version.solc": $solc_version, \
        "com.github.h4l.devcontainer-features.solc.version.z3": $z3_version, \
    } \
}' > .oras-annotations.json

FROM scratch AS binaries
COPY --from=solc-build /build/solc-build/solc/solc /
COPY --from=z3-build-libs /build/z3-versioned-lib-only/ /
COPY --from=binaries-metadata .oras-annotations.json /


FROM gcr.io/distroless/base-nossl-debian11 AS solc-distroless
COPY --from=solc-build /build/solc-build/solc/solc /solc
ENTRYPOINT ["/solc"]


# dynamically loading z3 doesn't work in the distroless image
FROM debian:${DEBIAN_VERSION_NAME:?}-slim AS solc-z3-debian
COPY --from=solc-build /build/solc-build/solc/solc /solc
COPY --from=z3-build-libs /build/z3-libs-debian/ /
ENTRYPOINT ["/solc"]
