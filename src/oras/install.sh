#!/bin/bash
set -euo pipefail

. ./ensure_command.sh
ensure_command curl

VERSION="${VERSION:-1.0.0}"
if [[ ! $VERSION =~ ^[a-zA-Z0-9.-]+$ ]]; then
  echo "Error: invalid version: $VERSION" >&2
  exit 1
fi

declare -A uname_platforms=([aarch64]=arm64 [x86_64]=amd64)
platform=${uname_platforms[$(uname -m)]:?"Error: unsupported platform: $(uname -m)"}

curl --fail --location -# -o oras.tar.gz \
  "https://github.com/oras-project/oras/releases/download/v${VERSION?}/oras_${VERSION:?}_linux_${platform:?}.tar.gz"
mkdir -p oras-install/
tar -zxf oras.tar.gz -C oras-install/
mv oras-install/oras /usr/local/bin/
rm -rf oras.tar.gz oras-install/
