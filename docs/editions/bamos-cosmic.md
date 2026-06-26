# 🖥️ BamOS COSMIC Edition

> **Image**: `ghcr.io/quocnho/bamos-cosmic`
> **Base**: Fedora Atomic 44 (Universal base)
> **Desktop**: COSMIC (System76)
> **GPU**: AMD/Intel

---

## 1. Hệ thống (System Layer)

### Nền tảng
- **Base image**: `ghcr.io/ublue-os/base-main:44` — Universal base image (không DE mặc định)
- **Cơ chế cập nhật**: `bootc` — atomic updates, rollback tức thì
- **Kiến trúc**: Immutable (OSTree-based), read-only rootfs
- **Signing**: Cosign — tất cả images đều được ký

### Kernel & Tuning
- **Kernel**: CachyOS kernel (thay thế kernel Fedora mặc định) — tối ưu cho hiệu năng & độ trễ thấp
- **Tuning packages**:
  - `ananicy-cpp` + `cachyos-ananicy-rules` — tự động điều chỉnh priority process
  - `cachyos-settings` — sysctl & scheduler tuning từ CachyOS
  - `bore-sysctl` — BORE CPU scheduler
  - `scx-scheds` + `scx-tools` — extensible schedulators

### Repositories đã thêm
| Repo | Mục đích |
|------|----------|
| RPM Fusion (free + nonfree) | Multimedia codecs, drivers |
| RakuOS COPR | RakuOS software center & welcome app |
| ublue-os/bazzite | Bazzite packages (gaming) |
| ublue-os/packages | Công cụ hữu ích từ ublue |
| Terra repos | Mesa cập nhật, multimedia |
| Flathub | Flatpak ứng dụng |
| COSMIC Flatpak repo | COSMIC desktop Flatpak apps |

### SELinux & Security
- **SELinux**: Permissive mode (`SELINUX=permissive`, targeted policy)
- **Container policy**: Trust `ghcr.io/quocnho` registry
- **Sudoers**: Passwordless sudo cho nhóm `wheel` với các lệnh `bamos`, `flatpak`, `bootc`

### System Services
| Service | Chức năng |
|---------|-----------|
| `flatpak-cleanup.timer` | Dọn dẹp Flatpak định kỳ |
| `rpm-ostree-clean-metadata.timer` | Dọn metadata RPM-OSTree |
| `rpm-ostree-clean-deployments.timer` | Dọn deployments cũ |
| `podman-prune.timer` | Dọn container không dùng |
| `cosmic-greeter.service` | COSMIC login screen |

### System Identifiers
- **OS Name**: BamOS Linux 44 (`ID=bamos`, `ID_LIKE=fedora`)
- **Hostname mặc định**: `bamos`
- **Variant**: `bootc`

---

## 2. Desktop Environment — COSMIC

### Desktop
- **COSMIC Desktop** — desktop environment thế hệ mới từ System76 (mặc định trên Pop!_OS)
- Cài đặt từ Fedora repositories vì base-main không có DE sẵn
- Sử dụng **Cosmic Greeter** (login screen)

### COSMIC DE Packages

| Package | Chức năng |
|---------|-----------|
| `cosmic-greeter` | Login screen / display manager |
| `cosmic-session` | Session manager (systemd-boot) |
| `cosmic-comp` | COSMIC compositor (Wayland) — COSMIC tự xây dựng, không dùng Mutter/KWin |
| `cosmic-panel` | Desktop panel (taskbar) |
| `cosmic-settings` | System settings center |
| `cosmic-settings-daemon` | Background settings daemon |
| `cosmic-wallpapers` | Bộ hình nền COSMIC |
| `cosmic-workspaces` | Workspace manager (tiling window-like) |
| `cosmic-applets` | Panel applets (clock, network, battery...) |
| `cosmic-bg` | Background service |
| `cosmic-launcher` | Ứng dụng launcher (giống Spotlight) |
| `cosmic-app-library` | App grid |
| `cosmic-notifications` | Notification daemon |
| `cosmic-idle` | Idle management (DPMS, lock screen) |
| `cosmic-osd` | On-screen display (volume, brightness...) |
| `cosmic-randr` | Display configuration (dựa trên RandR) |
| `cosmic-icon-theme` | Icon theme COSMIC |
| `xdg-desktop-portal-cosmic` | XDG Desktop Portal cho COSMIC (file picker, screenshot...) |

### COSMIC Configuration
- **Display server**: Wayland (mặc định, COSMIC native)
- **DE fonts**: @fonts group (Noto, Liberation, etc.)
- **Hardware support**: @hardware-support group
- **Theme**: COSMIC icon theme + Bibata cursor + adw-gtk3 theme
- **Skel config**: Cấu hình mặc định đặt trong `/etc/skel/.config`
- **COSMIC Flatpak repo**: `https://apt.pop-os.org/cosmic/cosmic.flatpakrepo`

---

## 3. Ứng dụng đã cài đặt

### Flatpak (System-wide)

| Ứng dụng | ID | Chức năng |
|-----------|-----|-----------|
| Mozilla Firefox | `org.mozilla.firefox` | Trình duyệt web |
| COSMIC Store | `com.system76.CosmicStore` | App store cho COSMIC |
| COSMIC Terminal | `com.system76.CosmicTerminal` | Terminal emulator COSMIC |
| COSMIC Files | `com.system76.CosmicFiles` | File manager COSMIC |
| COSMIC Settings | `com.system76.CosmicSettings` | Settings center (Flatpak) |
| COSMIC App Library | `com.system76.CosmicAppLibrary` | App library (Flatpak) |

### Công cụ RPM (System)

**Gaming & Hiệu năng:**
| Package | Chức năng |
|---------|-----------|
| `gamemode` + `gamemode.i686` | Tối ưu hiệu năng gaming (32 & 64-bit) |
| `GameMode` | Daemon tự động điều chỉnh CPU/GPU khi chơi game |

**Media & Multimedia:**
| Package | Chức năng |
|---------|-----------|
| `ffmpeg` (swapped từ ffmpeg-free) | Codec đầy đủ |
| `pulseaudio-utils` | Công cụ quản lý audio |
| `v4l-utils` | Webcam/video tools |

**Phát triển & Dev Tools:**
| Package | Chức năng |
|---------|-----------|
| `git` | Version control |
| `flatpak` | Containerized app runtime |
| `podman` + `podman-compose` | Container engine (rootless) |
| `distrobox` | Container-based development environments |
| `python3-pip` + `python3-setuptools` | Python toolchain |
| `jq` | JSON processor |
| `rsync` | File sync |

**Hệ thống & Tiện ích:**
| Package | Chức năng |
|---------|-----------|
| `dkms` + `akmods` | Kernel module building |
| `mokutil` | Machine Owner Key management |
| `lm_sensors` | Hardware monitoring |
| `libnotify` + `inotify-tools` | Notification & file watcher |
| `appstream` + `appstream-data` + `fwupd` | Firmware updates |
| `fuse` + `squashfuse` | Filesystem mount tools |
| `unzip` | Archive extraction |
| `libxcrypt-compat` | Legacy crypto compatibility |
| `openssl` + `sqlite3` | Security & databases |

**Fonts & Themes:**
| Package | Chức năng |
|---------|-----------|
| `@fonts` | Bộ font đầy đủ (Noto, Liberation, Google Fonts...) |
| `google-noto-sans-cjk-fonts` | Font CJK (Chinese, Japanese, Korean) |
| `google-noto-sans-mono-cjk-vf-fonts` | Font CJK monospace |
| `bibata-cursor-theme` | Modern cursor theme |
| `adw-gtk3-theme` | GTK3 theme phong cách GNOME |

### 32-bit Libraries (AMD/Intel only)
| Package | Chức năng |
|---------|-----------|
| `mesa-dri-drivers.i686` | Mesa DRI drivers 32-bit |
| `mesa-va-drivers.i686` | VA-API hardware video acceleration 32-bit |
| `mesa-vulkan-drivers.i686` | Vulkan drivers 32-bit |
| `mesa-libEGL.i686` | EGL library 32-bit |
| `mesa-libGL.i686` | OpenGL library 32-bit |

---

## 4. Môi trường & Thiết lập

### Environment Variables (Profile)
- **`BAMOS_ROOT`**: `/var/lib/bamos/packages` — thư mục gốc cho packages cài qua `bamos`
- **`PATH`**: Tự động thêm `$BAMOS_ROOT/usr/bin`, `$BAMOS_ROOT/usr/sbin`
- **`XDG_DATA_DIRS`**: Bao gồm `$BAMOS_ROOT/usr/share`
- **`MANPATH`**: Bao gồm `$BAMOS_ROOT/usr/share/man`
- **`GI_TYPELIB_PATH`**: Bao gồm `$BAMOS_ROOT/usr/lib64/girepository-1.0`
- **`FLATPAK_WRAPPERS`**: `/usr/local/bin/flatpak` — Flatpak wrappers trong PATH

### Package Management
- **`bamos`**: CLI tool quản lý gói nội bộ — `bamos install/remove/update`
- **dnf5 wrappers**: Tự động route `install/remove/update` qua `bamos`
- **Flatpak**: Flathub + COSMIC Flatpak repo + system-wide & user install hỗ trợ

### Network & Containers
- **`podman`**: Rootless container
- **`distrobox`**: Tạo dev environment từ container images
- **Container policy**: Cho phép insecureAcceptAnything từ `ghcr.io/quocnho`

---

## 5. Tổng quan

```
┌─────────────────────────────────────┐
│   Ứng dụng Flatpak COSMIC           │
│  Firefox · Store · Terminal · Files │
│  Settings · App Library             │
├─────────────────────────────────────┤
│      COSMIC Desktop (System76)      │
│   Cosmic Comp (Wayland) · Panel     │
│   Workspaces · Launcher · Greeter   │
├─────────────────────────────────────┤
│       CachyOS Kernel tuned          │
│   ananicy · bore-sched · scx-sched  │
├─────────────────────────────────────┤
│    Fedora Atomic 44 (base-main)     │
│   bootc · ostree · read-only rootfs │
└─────────────────────────────────────┘
```

### Use cases
✅ **Next-gen desktop** — COSMIC thế hệ mới, Rust-based compositor  
✅ **Tiling window** — Workspaces tích hợp sẵn, phù hợp developer workflow  
✅ **Gaming** — GameMode, CachyOS kernel, Mesa 32-bit  
✅ **Phát triển phần mềm** — Podman, Distrobox, Python, Rust-ready  
✅ **Đam mê công nghệ mới** — Trải nghiệm COSMIC sớm trên Fedora Atomic  
