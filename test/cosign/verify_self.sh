#!/bin/bash
set -e

# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

[[ $(uname -m) == "aarch64" ]] && arch=arm64 || arch=amd64

curl -o cosign-release.sig --fail -L https://github.com/sigstore/cosign/releases/download/v2.0.2/cosign-linux-${arch:?}-keyless.sig
base64 -d cosign-release.sig > cosign-release.sig.decoded

curl -o cosign-release.pem --fail -L https://github.com/sigstore/cosign/releases/download/v2.0.2/cosign-linux-${arch:?}-keyless.pem
base64 -d cosign-release.pem > cosign-release.pem.decoded

check "cosign verifies itself" \
  cosign verify-blob "$(command -v cosign)" \
  --certificate cosign-release.pem.decoded \
  --signature cosign-release.sig.decoded \
  --certificate-identity keyless@projectsigstore.iam.gserviceaccount.com \
  --certificate-oidc-issuer https://accounts.google.com

reportResults
