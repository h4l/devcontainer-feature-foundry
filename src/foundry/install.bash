#!/usr/bin/env bash
set -xeuo pipefail

VERSION=${VERSION:-}
BRANCH=${BRANCH:-}

source ./ensure_command.sh
ensure_command curl
ensure_command git

export FOUNDRY_DIR=/usr/local/share/foundry
FOUNDRY_BIN_DIR="$FOUNDRY_DIR/bin"
FOUNDRY_ROOT_MAN_DIR="$FOUNDRY_DIR/share/man"
FOUNDRY_MAN_DIR="$FOUNDRY_ROOT_MAN_DIR/man1"

BIN_URL="https://raw.githubusercontent.com/foundry-rs/foundry/master/foundryup/foundryup"
BIN_PATH="$FOUNDRY_BIN_DIR/foundryup"

# Create the .foundry bin directory and foundryup binary if it doesn't exist.
mkdir -p $FOUNDRY_BIN_DIR
curl -# -L $BIN_URL -o $BIN_PATH
chmod +x $BIN_PATH

# Create the man directory for future man files if it doesn't exist.
mkdir -p $FOUNDRY_MAN_DIR

# Add foundry to PATH & MANPATH
cat > /etc/profile.d/50-foundry.sh \
<< EOF
export PATH="${FOUNDRY_BIN_DIR:?}:\$PATH"
EOF

# Add the foundry manpages to the MANPATH
if [[ -e /etc/manpath.config ]]; then
 echo "MANDATORY_MANPATH $FOUNDRY_ROOT_MAN_DIR" >> /etc/manpath.config
fi

# Install foundry via foundryup
source /etc/profile.d/50-foundry.sh

INSTALL_ARGS=()
if [[ "$VERSION" != "" ]]; then
    INSTALL_ARGS+=(--version)
    INSTALL_ARGS+=($VERSION)
fi

foundryup "${INSTALL_ARGS[@]}"

