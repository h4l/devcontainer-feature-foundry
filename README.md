# Dev Container Features

This repo contains devcontainer features created by [h4l](https://github.com/h4l).

## Contents

This repository contains a _collection_ of just one Feature - `foundry`.

### `foundry`

Install the Foundry Ethereum toolkit via `foundryup`.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/h4l/devcontainer-features/foundry:1": {}
    }
}
```

## Repo and Feature Structure

This repo is based on [devcontainers/feature-starter](https://github.com/devcontainers/feature-starter). Each Feature has its own sub-folder, containing at least a `devcontainer-feature.json` and an entrypoint script `install.sh`. 
