#!/usr/bin/env bash
set -euo pipefail

# This generates install.sh.
# Usage:
# $ ./generate_install.sh v3.0.4 > ../../src/cosign/install.sh

version="${1:?Error: first argument must be a git revision}"
cosign_installer_url="https://raw.githubusercontent.com/sigstore/cosign-installer/${version:?}/action.yml"

action_yaml=$(curl --no-progress-meter --fail "${cosign_installer_url:?}") || {
  echo "Error: failed to download cosign-installer's Action YAML from ${cosign_installer_url:?}" >&2;
  exit 1
}
action_yaml_sha256=$(sha256sum - <<<"$action_yaml" | awk '{print $1}')
default_version=$(yq -er '.inputs["cosign-release"].default' - <<<"$action_yaml")

# actions.yaml uses these placeholders:
# ${{ inputs.cosign-release }}
# ${{ inputs.install-dir }}
# ${{ inputs.use-sudo }}
# ${{ runner.arch }}
# ${{ runner.os }}

# shellcheck disable=SC2016
install_script=$(yq -er '
.runs.steps[0].run
| gsub("\\${{ *inputs.cosign-release *}}"; "${COSIGN_VERSION:?}")
| gsub("\\${{ *inputs.install-dir *}}"; "${INSTALL_DIR:?}")
| gsub("\\${{ *inputs.use-sudo *}}"; "${USE_SUDO:?}")
| gsub("\\${{ *runner.arch *}}"; "${GHACTIONS_ARCH:?}")
| gsub("\\${{ *runner.os *}}"; "${GHACTIONS_OS:?}")
| (match("\\${{ *[^} ]+ *}}")
   | error("Actions placeholder remained after replacing known placeholders: \(.string)")
  ) // .
' - <<<"${action_yaml:?}")

cat<<<"\
$(head -n 1 <<<"${install_script:?}" `# shebang`)
#
# This install script was automatically extracted from the official
# cosign-installer GitHub Action:
# ${cosign_installer_url:?}
# sha256: ${action_yaml_sha256:?}
#
COSIGN_VERSION=\${VERSION:-${default_version:?}}
INSTALL_DIR=\${INSTALLDIR:?}
USE_SUDO=\${USESUDO:?}

declare -A GHACTIONS_ARCH_NAMES=([aarch64]=ARM64 [x86_64]=X64)
GHACTIONS_ARCH=\${GHACTIONS_ARCH_NAMES[\$(uname -m)]:-}
if [[ \$GHACTIONS_ARCH == \"\" ]]; then
  echo \"Error: unsupported CPU architecture: \$(uname -m)\" >&2
  exit 1
fi
GHACTIONS_OS=\$(uname -s)

. ensure_command.sh
ensure_command curl

$(tail -n +2 <<<"${install_script:?}")"
