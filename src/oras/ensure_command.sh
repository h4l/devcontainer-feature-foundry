ensure_apt_updated() {
    if [ "${_apt_updated:-}" != "true" ]; then
        apt-get update
        _apt_updated=true
    fi
}

ensure_command() {
    command=${1:?}
    package=${2:-$command}

    if ! which "$command" >/dev/null; then
        ensure_package "$package"
    fi
}

ensure_package() {
    package=${1:?}
    if which apt-get >/dev/null; then
        ensure_apt_updated
        apt-get -y install "$package"
    elif which apk >/dev/null; then
        apk add "${package}"
    else
        echo "Unable to install $package, no supported package manager found" >&2
        exit 1
    fi
}
