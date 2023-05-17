#!/bin/bash
#
# This install script was automatically extracted from the official
# cosign-installer GitHub Action:
# https://raw.githubusercontent.com/sigstore/cosign-installer/v3.0.4/action.yml
# sha256: bc1c34cefc456b4eb4b8e96992d83462984138ad418b5500006ac0e978274b9f
#
COSIGN_VERSION=${VERSION:-v2.0.2}
INSTALL_DIR=${INSTALLDIR:?}
USE_SUDO=${USESUDO:?}

declare -A GHACTIONS_ARCH_NAMES=([aarch64]=ARM64 [x86_64]=X64)
GHACTIONS_ARCH=${GHACTIONS_ARCH_NAMES[$(uname -m)]:-}
if [[ $GHACTIONS_ARCH == "" ]]; then
  echo "Error: unsupported CPU architecture: $(uname -m)" >&2
  exit 1
fi
GHACTIONS_OS=$(uname -s)

. ensure_command.sh
ensure_command curl

# cosign install script
shopt -s expand_aliases
if [ -z "$NO_COLOR" ]; then
  alias log_info="echo -e \"\033[1;32mINFO\033[0m:\""
  alias log_error="echo -e \"\033[1;31mERROR\033[0m:\""
else
  alias log_info="echo \"INFO:\""
  alias log_error="echo \"ERROR:\""
fi
set -e

mkdir -p ${INSTALL_DIR:?}

if [[ ${COSIGN_VERSION:?} == "main" ]]; then
  log_info "installing cosign via 'go install' from its main version"
  GOBIN=$(go env GOPATH)/bin
  go install github.com/sigstore/cosign/cmd/cosign@main
  ln -s $GOBIN/cosign ${INSTALL_DIR:?}/cosign
  exit 0
fi

shaprog() {
  case ${GHACTIONS_OS:?} in
    Linux)
      sha256sum $1 | cut -d' ' -f1
      ;;
    macOS)
      shasum -a256 $1 | cut -d' ' -f1
      ;;
    Windows)
      powershell -command "(Get-FileHash $1 -Algorithm SHA256 | Select-Object -ExpandProperty Hash).ToLower()"
      ;;
    *)
      log_error "unsupported OS ${GHACTIONS_OS:?}"
      exit 1
      ;;
  esac
}

bootstrap_version='v2.0.2'
bootstrap_linux_amd64_sha='dc641173cbda29ba48580cdde3f80f7a734f3b558a25e5950a4b19f522678c70'
bootstrap_linux_arm_sha='686ef6160889e84e5710505345b5b55cef0873907d0ef5954c837d9d647cf169'
bootstrap_linux_arm64_sha='517e96f9d036c4b77db01132cacdbef21e4266e9ad3a93e67773c590ba54e26f'
bootstrap_darwin_amd64_sha='0f51cbe19a315b919e87042f0485331821722ecb7fce22cc1b880ed4833fc8b0'
bootstrap_darwin_arm64_sha='55242a52ebca43dfb133d0fe26e11546bfa4571addd6852d782c119d74deade1'
bootstrap_windows_amd64_sha='782fcc768fca4dea9eb7464032de4b3e602f8d605b71bae686762e7622faa9ca'
cosign_executable_name=cosign

trap "popd >/dev/null" EXIT

pushd ${INSTALL_DIR:?} > /dev/null

case ${GHACTIONS_OS:?} in
  Linux)
    case ${GHACTIONS_ARCH:?} in
      X64)
        bootstrap_filename='cosign-linux-amd64'
        bootstrap_sha=${bootstrap_linux_amd64_sha}
        desired_cosign_filename='cosign-linux-amd64'
        # v0.6.0 had different filename structures from all other releases
        if [[ ${COSIGN_VERSION:?} == 'v0.6.0' ]]; then
          desired_cosign_filename='cosign_linux_amd64'
          desired_cosign_v060_signature='cosign_linux_amd64_0.6.0_linux_amd64.sig'
        fi
        ;;

      ARM)
        bootstrap_filename='cosign-linux-arm'
        bootstrap_sha=${bootstrap_linux_arm_sha}
        desired_cosign_filename='cosign-linux-arm'
        if [[ ${COSIGN_VERSION:?} == 'v0.6.0' ]]; then
          log_error "linux-arm build not available at v0.6.0"
          exit 1
        fi
        ;;

      ARM64)
        bootstrap_filename='cosign-linux-arm64'
        bootstrap_sha=${bootstrap_linux_arm64_sha}
        desired_cosign_filename='cosign-linux-arm64'
        if [[ ${COSIGN_VERSION:?} == 'v0.6.0' ]]; then
          log_error "linux-arm64 build not available at v0.6.0"
          exit 1
        fi
        ;;

      *)
        log_error "unsupported architecture $arch"
        exit 1
        ;;
    esac
    ;;

  macOS)
    case ${GHACTIONS_ARCH:?} in
      X64)
        bootstrap_filename='cosign-darwin-amd64'
        bootstrap_sha=${bootstrap_darwin_amd64_sha}
        desired_cosign_filename='cosign-darwin-amd64'
        # v0.6.0 had different filename structures from all other releases
        if [[ ${COSIGN_VERSION:?} == 'v0.6.0' ]]; then
          desired_cosign_filename='cosign_darwin_amd64'
          desired_cosign_v060_signature='cosign_darwin_amd64_0.6.0_darwin_amd64.sig'
        fi
        ;;

      ARM64)
        bootstrap_filename='cosign-darwin-arm64'
        bootstrap_sha=${bootstrap_darwin_arm64_sha}
        desired_cosign_filename='cosign-darwin-arm64'
        # v0.6.0 had different filename structures from all other releases
        if [[ ${COSIGN_VERSION:?} == 'v0.6.0' ]]; then
          desired_cosign_filename='cosign_darwin_arm64'
          desired_cosign_v060_signature='cosign_darwin_arm64_0.6.0_darwin_arm64.sig'
        fi
        ;;

      *)
        log_error "unsupported architecture $arch"
        exit 1
        ;;
    esac
    ;;

  Windows)
    case ${GHACTIONS_ARCH:?} in
      X64)
        bootstrap_filename='cosign-windows-amd64.exe'
        bootstrap_sha=${bootstrap_windows_amd64_sha}
        desired_cosign_filename='cosign-windows-amd64.exe'
        cosign_executable_name=cosign.exe
        # v0.6.0 had different filename structures from all other releases
        if [[ ${COSIGN_VERSION:?} == 'v0.6.0' ]]; then
          desired_cosign_filename='cosign_windows_amd64.exe'
          desired_cosign_v060_signature='cosign_windows_amd64_0.6.0_windows_amd64.exe.sig'
        fi
        ;;
      *)
        log_error "unsupported architecture $arch"
        exit 1
        ;;
    esac
    ;;
  *)
    log_error "unsupported architecture $arch"
    exit 1
    ;;
esac

SUDO=
if [[ "${USE_SUDO:?}" == "true" ]] && command -v sudo >/dev/null; then
  SUDO=sudo
fi

expected_bootstrap_version_digest=${bootstrap_sha}
log_info "Downloading bootstrap version '${bootstrap_version}' of cosign to verify version to be installed...\n      https://storage.googleapis.com/cosign-releases/${bootstrap_version}/${bootstrap_filename}"
$SUDO curl -sL https://storage.googleapis.com/cosign-releases/${bootstrap_version}/${bootstrap_filename} -o ${cosign_executable_name}
shaBootstrap=$(shaprog ${cosign_executable_name});
if [[ $shaBootstrap != ${expected_bootstrap_version_digest} ]]; then
  log_error "Unable to validate cosign version: '${COSIGN_VERSION:?}'"
  exit 1
fi
$SUDO chmod +x ${cosign_executable_name}

# If the bootstrap and specified `cosign` releases are the same, we're done.
if [[ ${COSIGN_VERSION:?} == ${bootstrap_version} ]]; then
  log_info "bootstrap version successfully verified and matches requested version so nothing else to do"
  exit 0
fi

semver='^v([0-9]+\.){0,2}(\*|[0-9]+)(-?r?c?)(\.[0-9]+)$'
if [[ ${COSIGN_VERSION:?} =~ $semver ]]; then
  log_info "Custom cosign version '${COSIGN_VERSION:?}' requested"
else
  log_error "Unable to validate requested cosign version: '${COSIGN_VERSION:?}'"
  exit 1
fi

# Download custom cosign
log_info "Downloading platform-specific version '${COSIGN_VERSION:?}' of cosign...\n      https://storage.googleapis.com/cosign-releases/${COSIGN_VERSION:?}/${desired_cosign_filename}"
$SUDO curl -sL https://storage.googleapis.com/cosign-releases/${COSIGN_VERSION:?}/${desired_cosign_filename} -o cosign_${COSIGN_VERSION:?}
shaCustom=$(shaprog cosign_${COSIGN_VERSION:?});

# same hash means it is the same release
if [[ $shaCustom != $shaBootstrap ]]; then
  if [[ ${COSIGN_VERSION:?} == 'v0.6.0' && ${GHACTIONS_OS:?} == 'Linux' ]]; then
    # v0.6.0's linux release has a dependency on `libpcsclite1`
    log_info "Installing libpcsclite1 package if necessary..."
    set +e
    sudo dpkg -s libpcsclite1
    if [ $? -eq 0 ]; then
        log_info "libpcsclite1 package is already installed"
    else
         log_info "libpcsclite1 package is not installed, installing it now."
         sudo apt-get update -q -q
         sudo apt-get install -yq libpcsclite1
    fi
    set -e
  fi

  if [[ ${COSIGN_VERSION:?} == 'v0.6.0' ]]; then
    log_info "Downloading detached signature for platform-specific '${COSIGN_VERSION:?}' of cosign...\n      https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION:?}/${desired_cosign_v060_signature}"
    $SUDO curl -sL https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION:?}/${desired_cosign_v060_signature} -o ${desired_cosign_filename}.sig
  else
    log_info "Downloading detached signature for platform-specific '${COSIGN_VERSION:?}' of cosign...\n      https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION:?}/${desired_cosign_filename}.sig"
    $SUDO curl -sLO https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION:?}/${desired_cosign_filename}.sig
  fi

  if [[ ${COSIGN_VERSION:?} < 'v0.6.0' ]]; then
    log_info "Downloading cosign public key '${COSIGN_VERSION:?}' of cosign...\n    https://raw.githubusercontent.com/sigstore/cosign/${COSIGN_VERSION:?}/.github/workflows/cosign.pub"
    RELEASE_COSIGN_PUB_KEY=https://raw.githubusercontent.com/sigstore/cosign/${COSIGN_VERSION:?}/.github/workflows/cosign.pub
  else
    log_info "Downloading cosign public key '${COSIGN_VERSION:?}' of cosign...\n    https://raw.githubusercontent.com/sigstore/cosign/${COSIGN_VERSION:?}/release/release-cosign.pub"
    RELEASE_COSIGN_PUB_KEY=https://raw.githubusercontent.com/sigstore/cosign/${COSIGN_VERSION:?}/release/release-cosign.pub
  fi

  log_info "Using bootstrap cosign to verify signature of desired cosign version"
  ./cosign verify-blob --insecure-ignore-tlog --key $RELEASE_COSIGN_PUB_KEY --signature ${desired_cosign_filename}.sig cosign_${COSIGN_VERSION:?}

  $SUDO rm cosign
  $SUDO mv cosign_${COSIGN_VERSION:?} ${cosign_executable_name}
  $SUDO chmod +x ${cosign_executable_name}
  log_info "Installation complete!"
fi
