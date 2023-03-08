#!/bin/bash
set -e

# https://github.com/devcontainers/cli/blob/main/docs/features/test.md
source dev-container-features-test-lib

apt-get update && apt-get install -y --no-install-recommends man-db
check "foundry man dir on MANPATH" bash -c 'manpath | grep -e "/usr/local/share/foundry/share/man:"'

reportResults
