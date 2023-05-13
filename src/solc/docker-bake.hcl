variable "REGISTRY" {
    default = ""
}

variable "SOLC_VERSION" {
  default = "0.8.20"
}

variable "Z3_VERSION" {
  default = "4.12.1"
}

variable "TAG_VERSION" {
    default = SOLC_VERSION
}

group "default" {
  targets = ["solc-distroless", "solc-z3-debian", "solc-z3-binaries"]
}

function "tag" {
    params = [name, version]
    result = "${join("/", compact([REGISTRY, name]))}:${version}"
}

target "_common" {
    platforms = ["linux/amd64", "linux/arm64"]
    args = {
        BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
    }
    contexts = {
        z3-src = "https://github.com/Z3Prover/z3.git#z3-${Z3_VERSION}"
        solc-src = "https://github.com/ethereum/solidity.git#v${SOLC_VERSION}"
    }
}

target "solc-distroless" {
    inherits = ["_common"]
    target = "solc-distroless"
    tags = [tag("solc", TAG_VERSION)]
}

target "solc-z3-debian" {
    inherits = ["_common"]
    target = "solc-z3-debian"
    tags = [tag("solc-z3-debian", TAG_VERSION)]
}
target "solc-z3-binaries" {
    inherits = ["_common"]
    target = "binaries"
    tags = [tag("solc-z3-binaries", TAG_VERSION)]
    output = ["binaries"]
}
