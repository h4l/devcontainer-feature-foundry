#!/bin/bash
set -e

# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

function run_or_fail_with_glibc_error() {( set -euo pipefail
    status=0
    output="$( "$@" 2>&1 )" || status=$?
    if [[ $status != 0 ]]; then
        if [[ ! $output == *"cannot execute: required file not found"* ]]; then
            echo -e "$1 failed with unexpected output:\n$output" >&2
            exit 1
        fi
        echo -e "\
Warning: command failed in expected manner due to glibc dependency on alpine:
$output"
    fi
)}

check "foundry command available: foundryup" foundryup --help

# Foundry doesn't currently ship binaries that work with alpine's musl libc. But
# I don't want the feature to fail on alpine, otherwise it causes the VSCode
# recovery container to fail, as it's based on alpine. (This happens if user
# adds a feature via their dev.containers.defaultFeatures setting.)
# So the feature still installs on alpine without failing, but the commands
# won't actually work until foundry provide musl libc builds.
check "foundry command available: forge"  run_or_fail_with_glibc_error forge --version
check "foundry command available: cast"   run_or_fail_with_glibc_error cast --version
check "foundry command available: anvil"  run_or_fail_with_glibc_error anvil --version
check "foundry command available: chisel" run_or_fail_with_glibc_error chisel --version

reportResults
