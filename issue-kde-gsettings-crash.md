# Bug: Add button (and other UI interactions) broken on KDE Plasma — unhandled GSettings exception in `apply_dark_theme()`

## Description

On KDE Plasma desktops (e.g. Bazzite, Aurora, KDE Neon, openSUSE with KDE), clicking the **"+" (Add Game/App) button does nothing**. The same applies to any other interaction that depends on `do_startup()` having completed successfully.

## Root Cause

`apply_dark_theme()` in `faugus/utils.py` calls:

```python
desktop_env = Gio.Settings.new("org.gnome.desktop.interface")
```

This line is **not wrapped in a try/except**. On KDE Plasma the `org.gnome.desktop.interface` GSettings schema is typically not installed, so `Gio.Settings.new()` raises an unhandled `gi.repository.GLib.Error`. Because this happens inside `FaugusApp.do_startup()`, the application's startup is aborted and the main window is left in a broken state — buttons are visible but click handlers never fire.

## Steps to Reproduce

1. Use a KDE Plasma desktop (Bazzite, Aurora, KDE Neon, openSUSE KDE, …)
2. Install Faugus Launcher (native package, not Flatpak)
3. Launch it and click the **"+"** button — nothing happens

## Expected Behavior

The launcher starts normally on KDE. Dark-theme detection gracefully falls back when the GNOME schema is unavailable.

## Suggested Fix

Wrap the schema lookup in a try/except in `faugus/utils.py`:

```python
def apply_dark_theme():
    if IS_FLATPAK:
        # … unchanged …
    else:
        try:
            desktop_env = Gio.Settings.new("org.gnome.desktop.interface")
            try:
                is_dark_theme = desktop_env.get_string("color-scheme") == "prefer-dark"
            except Exception:
                is_dark_theme = "-dark" in desktop_env.get_string("gtk-theme")
        except Exception:
            # org.gnome.desktop.interface schema not available (KDE / non-GNOME desktops)
            is_dark_theme = False
        if is_dark_theme:
            Gtk.Settings.get_default().set_property("gtk-application-prefer-dark-theme", True)
```

## Environment

- **Distro:** Bazzite / Aurora (also reproducible on any KDE Plasma system without GNOME schemas)
- **Desktop:** KDE Plasma
- **Faugus Launcher version:** 1.22.6
- **Installation method:** native package (non-Flatpak)

## Background

I discovered this bug while working on an unofficial AppImage build of Faugus Launcher for systems where no native package is available (e.g. immutable distros like Bazzite or Aurora that don't use RPM/DEB directly). The project is available at:

👉 https://github.com/Bitpainter75/faugus-launcher-appimage

This might also be of interest if you ever consider providing an official AppImage release — it would make Faugus Launcher available on any Linux distribution without requiring a package manager.
