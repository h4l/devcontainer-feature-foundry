#!/bin/bash
set -e

# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

check "/home/vscode has a mount" bash -c 'mount | grep -P "\s/home/vscode\s"'
check "HOME_DIRECTORY_VOLUME_NAME is set" \
    bash -c '[[ "${HOME_DIRECTORY_VOLUME_NAME:?}" == "devcontainer-home-dir" ]]'

reportResults
