#!/bin/bash
set -e

# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

check "oras command available" oras version

reportResults
