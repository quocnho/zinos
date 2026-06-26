# BamOS Linux &nbsp; [![bluebuild build badge](https://github.com/quocnho/bamos/actions/workflows/build.yml/badge.svg)](https://github.com/quocnho/bamos/actions/workflows/build.yml)

**BamOS** is an atomic, image-based Linux distribution built on Fedora Atomic. It combines the stability of immutable infrastructure with the flexibility of native package management.

Built with [BlueBuild](https://blue-build.org/). Design inspired by [RakuOS](https://rakuos.org/).

## Editions

| Edition | Desktop | GPU Support | Image |
|---------|---------|-------------|-------|
| BamOS KDE | KDE Plasma | AMD/Intel | `ghcr.io/quocnho/bamos-kde` |
| BamOS KDE NVIDIA | KDE Plasma | NVIDIA | `ghcr.io/quocnho/bamos-kde-nvidia` |
| BamOS GNOME | GNOME | AMD/Intel | `ghcr.io/quocnho/bamos-gnome` |
| BamOS GNOME NVIDIA | GNOME | NVIDIA | `ghcr.io/quocnho/bamos-gnome-nvidia` |
| BamOS COSMIC | COSMIC | AMD/Intel | `ghcr.io/quocnho/bamos-cosmic` |
| BamOS COSMIC NVIDIA | COSMIC | NVIDIA | `ghcr.io/quocnho/bamos-cosmic-nvidia` |

## Features

- 🚀 **Atomic updates** via `bootc` — instant rollback, no partial upgrades
- ⚡ **CachyOS kernel** — optimized performance and responsiveness
- 📦 **Native package management** — install RPMs directly, no layering
- 🎮 **Gaming ready** — Steam, Lutris, MangoHud, GameMode
- 🛡️ **Immutable base** — system integrity protected at all times
- 🔄 **Daily builds** — always up to date with the latest security patches

## Installation

> [!WARNING]
> This is an experimental feature. Try at your own discretion.

To rebase an existing Fedora Atomic installation:

```bash
# First rebase to unsigned image (for signing keys and policies)
sudo bootc switch ghcr.io/quocnho/bamos-kde:latest
sudo systemctl reboot

# After reboot, switch to signed image
sudo bootc switch ostree-image-signed:docker://ghcr.io/quocnho/bamos-kde:latest
sudo systemctl reboot
```

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign):

```bash
cosign verify --key cosign.pub ghcr.io/quocnho/bamos-kde
```

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed setup instructions.
