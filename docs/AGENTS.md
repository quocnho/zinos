# BamOS — Project Instructions

This project builds **BamOS Linux**, a custom Fedora Atomic distribution with 6 editions.

## Project Structure

```
bamos/
├── .github/workflows/build.yml   # Matrix CI: 6 editions × 2 parallel
├── recipes/
│   ├── bamos-kde.yml             # KDE Plasma + AMD/Intel
│   ├── bamos-kde-nvidia.yml      # KDE Plasma + NVIDIA
│   ├── bamos-gnome.yml           # GNOME + AMD/Intel
│   ├── bamos-gnome-nvidia.yml    # GNOME + NVIDIA
│   ├── bamos-cosmic.yml          # COSMIC + AMD/Intel
│   └── bamos-cosmic-nvidia.yml   # COSMIC + NVIDIA
├── files/
│   ├── scripts/
│   │   ├── 00-build-setup.sh     # Repos, kernel, core pkgs
│   │   ├── 01-install-packages.sh# DE-specific packages
│   │   ├── 02-post-build.sh      # Initramfs, final touches
│   │   └── 03-nvidia-setup.sh    # NVIDIA driver config
│   └── system/                   # Shared system files (copied to /)
│       ├── etc/
│       │   ├── containers/policy.json
│       │   ├── profile.d/
│       │   ├── selinux/config
│       │   └── sudoers.d/
│       └── usr/
│           ├── lib/os-release
│           ├── lib/fedora-release
│           └── share/bamos/logo.txt
├── files/kde-system/             # KDE-specific configs
├── files/gnome-system/           # GNOME-specific configs
├── files/cosmic-system/          # COSMIC-specific configs
├── AGENTS.md
├── DEVELOPMENT.md
├── README.md
└── cosign.pub
```

## Editions

| Recipe | Base Image | DE | GPU |
|--------|-----------|-----|-----|
| `bamos-kde.yml` | `kinoite-main:44` | KDE Plasma | AMD/Intel |
| `bamos-kde-nvidia.yml` | `kinoite-main:44` | KDE Plasma | NVIDIA |
| `bamos-gnome.yml` | `silverblue-main:44` | GNOME | AMD/Intel |
| `bamos-gnome-nvidia.yml` | `silverblue-main:44` | GNOME | NVIDIA |
| `bamos-cosmic.yml` | `cosmic-main:44` | COSMIC | AMD/Intel |
| `bamos-cosmic-nvidia.yml` | `cosmic-main:44` | COSMIC | NVIDIA |

## Important Conventions

1. **Build**: Uses BlueBuild — recipe.yml in `recipes/` directory
2. **Signing**: Cosign — keep `cosign.pub` in repo
3. **Secrets**: Never commit plaintext secrets. Use GitHub Secrets
4. **Changes**: Always test with `bluebuild build recipes/bamos-*.yml` before committing
5. **Commit messages**: Follow Conventional Commits format
6. **ISO generation**: Manual only (not automated in CI)
