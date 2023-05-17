#!/bin/bash
set -e

# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

check "cosign command available" cosign version

reportResults
