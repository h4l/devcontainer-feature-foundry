#!/bin/bash
set -e

# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

check "foundry command available: foundryup" foundryup --help
check "foundry command available: forge" forge --version
check "foundry command available: cast" cast --version
check "foundry command available: anvil" anvil --version
check "foundry command available: chisel" chisel --version

reportResults
