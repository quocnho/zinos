# 🖥️ BamOS KDE Plasma Edition

> **Image**: `ghcr.io/quocnho/bamos-kde`
> **Base**: Fedora Kinoite 44 (Atomic)
> **Desktop**: KDE Plasma
> **GPU**: AMD/Intel

---

## 1. Hệ thống (System Layer)

### Nền tảng
- **Base image**: `ghcr.io/ublue-os/kinoite-main:44` — Fedora Atomic với KDE Plasma
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

### System Identifiers
- **OS Name**: BamOS Linux 44 (`ID=bamos`, `ID_LIKE=fedora`)
- **Hostname mặc định**: `bamos`
- **Variant**: `bootc`

---

## 2. Desktop Environment — KDE Plasma

### Desktop
- **KDE Plasma** từ Kinoite base — đầy đủ workspace, widget, panel, KWin compositor

### Packages đã gỡ bỏ
| Package | Lý do |
|---------|-------|
| `plasma-discover` | Thay thế bằng giải pháp quản lý gói nội bộ |
| `plasma-discover-offline-updates` | Không cần với cơ chế atomic update |
| `plasma-discover-packagekit` | Không tương thích với RPM-OSTree |
| `plasma-welcome` | Trang chào mừng mặc định |
| `plasma-welcome-fedora` | Fedora-specific welcome |

### KDE Configuration
- **Font hệ thống**: Noto Sans, 10pt
- **Font rendering**: Antialias, hinting (hintslight)
- **Theme**: Bibata cursor theme, adw-gtk3 theme
- **KDE About**: Tùy chỉnh kcm-about-distrorc hiển thị "BamOS Linux"

---

## 3. Ứng dụng đã cài đặt

### Flatpak (System-wide)

| Ứng dụng | ID | Chức năng |
|-----------|-----|-----------|
| Mozilla Firefox | `org.mozilla.firefox` | Trình duyệt web |
| Gwenview | `org.kde.gwenview` | Xem ảnh |
| KCalc | `org.kde.kcalc` | Máy tính |
| Okular | `org.kde.okular` | Xem PDF/tài liệu |

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
- **Flatpak**: Flathub + system-wide & user install hỗ trợ

### Network & Containers
- **`podman`**: Rootless container
- **`distrobox`**: Tạo dev environment từ container images
- **Container policy**: Cho phép insecureAcceptAnything từ `ghcr.io/quocnho`

### Cleanup Automation
- Tự động dọn Flatpak cache, RPM-OSTree metadata, deployments cũ, Podman dangling resources

---

## 5. Tổng quan

```
┌─────────────────────────────────────┐
│         Ứng dụng Flatpak            │
│  Firefox · Gwenview · KCalc · Okular│
├─────────────────────────────────────┤
│       KDE Plasma Desktop            │
│   Panel · Widgets · KWin · Dolphin  │
├─────────────────────────────────────┤
│       CachyOS Kernel tuned          │
│   ananicy · bore-sched · scx-sched  │
├─────────────────────────────────────┤
│     Fedora Atomic 44 (Kinoite)      │
│   bootc · ostree · read-only rootfs │
└─────────────────────────────────────┘
```

### Use cases
✅ **Desktop hàng ngày** — KDE Plasma mạnh mẽ, tùy biến cao  
✅ **Gaming** — GameMode, CachyOS kernel, Mesa 32-bit  
✅ **Phát triển phần mềm** — Podman, Distrobox, Python, Git  
✅ **Đa phương tiện** — FFmpeg đầy đủ, VA-API  
✅ **Học tập & nghiên cứu** — CJK fonts, dev tools đầy đủ  
