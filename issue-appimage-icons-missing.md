# Bug: Button icons (`faugus-*-symbolic`) not displayed when running outside a system installation

## Description

When Faugus Launcher is run from a location that is not registered in the system's XDG data directories (e.g. an AppImage, a portable directory, or a manual install without running the icon-cache update), **all toolbar button icons are blank**. The buttons are present and clickable, but they show no image.

Affected icons: `faugus-add-symbolic`, `faugus-play-symbolic`, `faugus-settings-symbolic`, `faugus-kill-symbolic`, `faugus-stop-symbolic`, `faugus-exit-symbolic`.

## Root Cause

Button images are loaded via `Gtk.Image.new_from_icon_name()`:

```python
btn.set_image(Gtk.Image.new_from_icon_name(icon_name, Gtk.IconSize.BUTTON))
```

This relies on the GTK default icon theme, which is built from `XDG_DATA_DIRS` **at the time GTK initialises** — before any Python code runs. If the application's `usr/share/icons` directory is not part of the system's XDG_DATA_DIRS at that point, GTK never finds the custom symbolic icons and silently renders nothing.

## Steps to Reproduce

1. Run Faugus Launcher from any path not registered in the system icon theme cache (e.g. portable / AppImage use)
2. The toolbar buttons (+, ▶, ⚙, ✕, …) show no icon — only an empty square

## Expected Behavior

Button icons are always visible regardless of how or from where the application is started.

## Suggested Fix

Register the application's own icon directory with the GTK icon theme at startup in `faugus/launcher.py`, inside `FaugusApp.do_startup()`:

```python
def do_startup(self):
    Gtk.Application.do_startup(self)
    os.environ["GTK_USE_PORTAL"] = "1"

    # Ensure bundled symbolic icons are found even outside a system install
    app_icon_dir = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "..", "share", "icons"
    )
    app_icon_dir = os.path.normpath(app_icon_dir)
    if os.path.isdir(app_icon_dir):
        Gtk.IconTheme.get_default().prepend_search_path(app_icon_dir)

    apply_dark_theme()
```

This is safe for system installs (the path will already be in the theme) and fixes non-standard deployments without requiring external environment variables.

## Environment

- **Distro:** Bazzite / Aurora (also reproducible on any distro when running outside a normal system install)
- **Desktop:** KDE Plasma
- **Faugus Launcher version:** 1.22.6
- **Installation method:** AppImage / portable run

## Background

I discovered this bug while working on an unofficial AppImage build of Faugus Launcher, aimed at making it easy to run on immutable distros like Bazzite or Aurora without needing a package manager. The project is available at:

👉 https://github.com/Bitpainter75/faugus-launcher-appimage

If you are ever interested in providing an official AppImage release, the fix above would be a good first step — and I'd be happy to share more of what I've learned building and testing the AppImage.
