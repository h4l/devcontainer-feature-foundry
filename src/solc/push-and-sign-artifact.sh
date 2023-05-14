#!/usr/bin/env bash
set -xeuo pipefail

fail() {
    echo "${1:?no error message specified}" >&2
    exit 1
}

usage_error() {
    fail "usage: push-and-sign-artifact.sh <path> <repo-tag>"
}

( (( $# == 2 )) && [[ ${1:-} != "" ]] && [[ ${2:-} != "" ]] ) || usage_error
path=${1:?}
repo_tag=${2:?}

if [[ $repo_tag =~ , ]]; then
    fail "Error: multiple tags with commas are not supported"
fi

cd "${path:?}"

[[ -f .oras-annotations.json ]] \
    || fail "No file .oras-annotations.json exists at path: $path"

# Upload the binaries to an OCI repository as OCI Artifacts using oras.
oras_out=$(oras push --annotation-file .oras-annotations.json \
             "${repo_tag:?}" ./* )

# I can't see a way to get structured output from oras, so we have to parse
# stdout to get the digest it created, so we can sign it unambiguously.
pushed_digest=$(jq <<<"$oras_out" -eRr \
    'match("^Digest: (sha256:\\w{64})$") | .captures[0].string') \
    || fail "Error: failed to parse digest from oras stdout"

# Sign the tag digest with cosign so that people can validate that it was
# created in the CI job this is running in.
# We don't need --recursive as we're pushing single image manifests, not lists.
cosign sign --yes "${repo_tag:?}@${pushed_digest:?}"
