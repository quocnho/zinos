# 🖥️ BamOS COSMIC Edition — NVIDIA

> **Image**: `ghcr.io/quocnho/bamos-cosmic-nvidia`
> **Base**: Fedora Atomic 44 (Universal base)
> **Desktop**: COSMIC (System76)
> **GPU**: NVIDIA (proprietary driver)

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
| RPM Fusion (free + nonfree) | Multimedia codecs, NVIDIA drivers |
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
| `nvidia-powerd.service` | Quản lý điện năng NVIDIA |
| `nvidia-persistenced.service` | Duy trì NVIDIA driver state |

### System Identifiers
- **OS Name**: BamOS Linux 44 (`ID=bamos`, `ID_LIKE=fedora`)
- **Hostname mặc định**: `bamos`
- **Variant**: `bootc`

---

## 2. Desktop Environment — COSMIC

### Desktop
- **COSMIC Desktop** — desktop environment thế hệ mới từ System76
- Cài đặt từ Fedora repositories vì base-main không có DE sẵn
- Sử dụng **Cosmic Greeter** (login screen)

### COSMIC DE Packages

| Package | Chức năng |
|---------|-----------|
| `cosmic-greeter` | Login screen / display manager |
| `cosmic-session` | Session manager (systemd-boot) |
| `cosmic-comp` | COSMIC compositor (Wayland) |
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
| `xdg-desktop-portal-cosmic` | XDG Desktop Portal cho COSMIC |

### COSMIC Configuration
- **Display server**: Wayland (mặc định, COSMIC native)
- **DE fonts**: @fonts group
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

**NVIDIA Driver Stack:**
| Package | Chức năng |
|---------|-----------|
| `dkms-nvidia` | NVIDIA kernel module (DKMS) — tự động rebuild với kernel mới |
| `nvidia-driver` | NVIDIA proprietary driver + Vulkan/OpenGL/EGL |
| `nvidia-persistenced` | Duy trì GPU initialization giữa các lần suspend |
| `nvidia-gpu-firmware` | Firmware NVIDIA GPU |
| `mesa-vulkan-drivers` (reinstall) | Vulkan drivers (giữ compatibility với nouveau) |
| `nvidia-powerd` | Dynamic power management cho NVIDIA GPU |

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
| `@fonts` | Bộ font đầy đủ |
| `google-noto-sans-cjk-fonts` | Font CJK (Chinese, Japanese, Korean) |
| `google-noto-sans-mono-cjk-vf-fonts` | Font CJK monospace |
| `bibata-cursor-theme` | Modern cursor theme |
| `adw-gtk3-theme` | GTK3 theme phong cách GNOME |

> **Lưu ý**: Edition NVIDIA KHÔNG bao gồm 32-bit Mesa libraries — NVIDIA base đã có đủ drivers.

---

## 4. Cấu hình NVIDIA

### Kernel Module (modprobe)
File: `/etc/modprobe.d/nvidia-modeset.conf`
```
options nvidia_drm modeset=1 fbdev=1       # Wayland support
options nvidia NVreg_EnableMSI=1           # MSI interrupts
options nvidia NVreg_OpenRmEnableUnsupportedGpus=1  # OpenRM fallback
```

### Environment Variables
File: `/etc/environment.d/10-nvidia.conf`
| Variable | Value | Mục đích |
|----------|-------|----------|
| `GBM_BACKEND` | `nvidia-drm` | Wayland với COSMIC compositor |
| `__GLX_VENDOR_LIBRARY_NAME` | `nvidia` | Sử dụng NVIDIA GLX |
| `WLR_NO_HARDWARE_CURSORS` | `1` | Fix cursor (Wlroots-based compositor) |
| `GSK_RENDERER` | `gl` | GTK4 apps (COSMIC apps) hoạt động trên NVIDIA |

### udev Rules
File: `/etc/udev/rules.d/80-nvidia-pm.rules`
- Tự động load `nvidia-drm` và `nvidia-uvm` khi NVIDIA device được phát hiện

### Systemd Services (NVIDIA)

| Service | Chức năng |
|---------|-----------|
| `nvidia-powerd.service` | Dynamic power management |
| `nvidia-persistenced.service` | Giữ NVIDIA driver state persistent |
| `nvidia-suspend.service` | Xử lý suspend/resume (tránh GPU crash) |

---

## 5. Môi trường & Thiết lập

### Environment Variables (Profile)
- **`BAMOS_ROOT`**: `/var/lib/bamos/packages`
- **`PATH`**: Tự động thêm `$BAMOS_ROOT/usr/bin`, `$BAMOS_ROOT/usr/sbin`
- **`XDG_DATA_DIRS`**: Bao gồm `$BAMOS_ROOT/usr/share`
- **`GI_TYPELIB_PATH`**: Bao gồm `$BAMOS_ROOT/usr/lib64/girepository-1.0`
- **`FLATPAK_WRAPPERS`**: `/usr/local/bin/flatpak`

### Package Management
- **`bamos`**: CLI tool quản lý gói nội bộ
- **dnf5 wrappers**: Tự động route `install/remove/update` qua `bamos`
- **Flatpak**: Flathub + COSMIC Flatpak repo + system-wide & user install

### Network & Containers
- **`podman`**: Rootless container
- **`distrobox`**: Tạo dev environment từ container images

---

## 6. Tổng quan

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
│     NVIDIA Proprietary Driver       │
│   nvidia-drm · Wayland · Vulkan     │
│   Dynamic PM · Suspend/Resume       │
├─────────────────────────────────────┤
│       CachyOS Kernel tuned          │
│   ananicy · bore-sched · scx-sched  │
├─────────────────────────────────────┤
│    Fedora Atomic 44 (base-main)     │
│   bootc · ostree · read-only rootfs │
└─────────────────────────────────────┘
```

### Use cases
✅ **Next-gen desktop + NVIDIA** — COSMIC Rust-based compositor trên NVIDIA  
✅ **AI/ML workloads** — CUDA-ready trên COSMIC, Python, Podman  
✅ **Developer-first workflow** — Workspaces tiling-style, Cosmic Terminal, launcher  
✅ **Gaming trên NVIDIA** — GameMode, DKMS driver, Vulkan  
✅ **Cutting-edge experience** — COSMIC + Fedora Atomic + NVIDIA Wayland  
