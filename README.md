# Faugus Launcher — AppImage

Unofficial AppImage build of [Faugus Launcher](https://github.com/Faugus/faugus-launcher), a lightweight GTK3 GUI for running Windows games on Linux via [UMU-Launcher](https://github.com/Open-Wine-Components/umu-launcher) and Proton.

> This repository provides only the AppImage build scripts and releases.  
> All application code belongs to the [original project](https://github.com/Faugus/faugus-launcher) by Faugus (MIT License).

---

## Download

Grab the latest AppImage from the [Releases](../../releases/latest) page.

```bash
chmod +x faugus-launcher-*-x86_64.AppImage
./faugus-launcher-*-x86_64.AppImage
```

---

## Requirements

Install these two packages on the target system — everything else is bundled inside the AppImage.

### Fedora / Bazzite / Aurora / Nobara

```bash
sudo dnf install python3-gobject SDL2
```

### Ubuntu / Debian

```bash
sudo apt install python3-gi libsdl2-2.0-0
```

### Arch / CachyOS / Manjaro

```bash
sudo pacman -S python-gobject sdl2
```

> **Why?** `python3-gobject` provides the GTK3 Python bindings (`gi`), which cannot be bundled portably. `SDL2` is required by the bundled `pygame` for gamepad support.

---

## What's bundled

| Component | Details |
|---|---|
| Python packages | `requests`, `vdf`, `psutil`, `icoextract`, `pillow`, `pygame` |
| Pillow native libs | bundled in `pillow.libs/` — no system Pillow needed |
| pygame C-extensions | compiled for **Python 3.14** (Fedora 44 / Bazzite / Aurora) |
| `libayatana-appindicator3` | system tray icon support |
| `libdbusmenu-glib` + `libdbusmenu-gtk3` | dbusmenu backend for tray |
| `libcanberra` + audio backends | notification sound (ALSA, PulseAudio) |
| Button icons | `faugus-*-symbolic.svg` registered in the hicolor icon theme |

**Not bundled (must exist on the system):** GTK3, `python3-gobject`, SDL2.

---

## Compatibility

| Distribution | Status |
|---|---|
| Bazzite / Aurora (Fedora 44) | ✅ tested |
| Fedora 40+ | ✅ expected (Python 3.12+) |
| Ubuntu 24.04+ | ✅ expected |
| Arch / CachyOS | ✅ tested |
| Older distros with Python ≤ 3.13 | ❌ pygame C-extensions require Python 3.14 |

---

## Build it yourself

### Prerequisites (Arch / CachyOS)

```bash
sudo pacman -S git wget python librsvg
```

### Build

```bash
git clone https://github.com/Bitpainter75/faugus-launcher-appimage.git
cd faugus-launcher-appimage
chmod +x build-faugus-appimage.sh
./build-faugus-appimage.sh
```

The script will:
1. Download `appimagetool` and `linuxdeploy` automatically if not present
2. Clone the faugus-launcher source repository
3. Install all Python dependencies into the AppDir via a temporary venv
4. Bundle `libayatana-appindicator3`, `libdbusmenu` and `libcanberra`
5. Register symbolic icons in the GTK hicolor theme directory
6. Pack everything into `faugus-launcher-<version>-x86_64.AppImage`

No system-wide `pip` installation required.

---

## Links

- [Faugus Launcher (upstream)](https://github.com/Faugus/faugus-launcher)
- [UMU-Launcher](https://github.com/Open-Wine-Components/umu-launcher)
- [Support Faugus on Ko-fi](https://ko-fi.com/Faugus)
