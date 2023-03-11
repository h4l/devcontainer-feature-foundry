# Dev Container Features

This repo contains devcontainer features created by [h4l](https://github.com/h4l).

## Contents

This repository contains a _collection_ of Features:

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

### `home-dir-volume`

Mount a Docker volume named `devcontainer-home-dir` at `/home/vscode` in the devcontainer.

This allows all devcontainers used by a single user to share the same home
directory. This can be beneficial for a few reasons:

- devcontainers can share caches, which speeds up the install of personal dotfiles
  repos on container start
- Shell history is preserved over devcontainer rebuilds
- files can be moved between containers via the home directory

Cons:

- Security: this reduces isolation between containers in that each devcontainer
  sees the same binaries, shell configuration, etc from the shared home directory volume.

This is intended to be used by an individual via their `dev.containers.defaultFeatures` vscode setting.

> **Note:**
> The name of the volume and home directory path cannot be configured, because
> the _devcontainers feature_ feature does not provide a way to dynamically generate
> mounts, they have to be specified statically in the feature's JSON
> configuration.

```jsonc
// user settings JSON
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/h4l/devcontainer-features/home-dir-volume:1": {}
  }
}
```

## Repo and Feature Structure

This repo is based on [devcontainers/feature-starter](https://github.com/devcontainers/feature-starter). Each Feature has its own sub-folder, containing at least a `devcontainer-feature.json` and an entrypoint script `install.sh`.
