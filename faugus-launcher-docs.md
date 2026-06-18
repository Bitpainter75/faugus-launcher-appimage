# Faugus Launcher

**Version:** 1.22.4 | **Lizenz:** MIT | **Sprache:** Python (99%) | **GTK:** 3.0

Ein schlanker grafischer Launcher zum Ausführen von Windows-Spielen unter Linux via [UMU-Launcher](https://github.com/Open-Wine-Components/umu-launcher) und Proton.

---

## Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [Features](#features)
3. [Architektur & Projektstruktur](#architektur--projektstruktur)
4. [Abhängigkeiten](#abhängigkeiten)
5. [Installation](#installation)
6. [Verwendung](#verwendung)
7. [Konfiguration](#konfiguration)
8. [Gamepad-Unterstützung](#gamepad-unterstützung)
9. [AppImage bauen](#appimage-bauen)
10. [Bekannte Einschränkungen](#bekannte-einschränkungen)

---

## Übersicht

Faugus Launcher ist eine GTK3-Anwendung (App-ID: `io.github.Faugus.faugus-launcher`), die als grafische Oberfläche für UMU-Launcher fungiert. Sie ermöglicht die Verwaltung einer Spielebibliothek, die Auswahl von Proton-Versionen und die Konfiguration von Wine-Prefixes — ohne Steam zwingend vorauszusetzen.

---

## Features

- **Spielebibliothek** mit drei Ansichtsmodi: Liste, Blöcke, Banner
- **Sortiermöglichkeiten:** Alphabetisch, Spielzeit, Zuletzt gespielt, Benutzerdefiniert
- **Kategorien** zum Gruppieren von Spielen
- **Proton/Runner-Verwaltung** inkl. Download-Interface
- **Steam-Integration:** Liest installierte Spiele und Proton-Versionen aus
- **Desktop-Shortcuts** und App-Launcher-Einträge erstellen
- **Gamepad-Navigation** (PlayStation & Xbox Controller)
- **System-Tray-Icon** (via AyatanaAppIndicator3)
- **Autostart-Konfiguration**
- **Logging-Viewer** für Spielstarts
- **EA-App-Fix** integriert
- **Mehrsprachig** (Verzeichnis `languages/`)

---

## Architektur & Projektstruktur

```
faugus-launcher/
├── faugus-launcher          # Einstiegspunkt (Shell-Wrapper, ruft /usr/bin/python3 auf)
├── faugus_run.py            # Prozess-Runner (wird als `faugus-run` installiert)
├── meson.build              # Build-Konfiguration
├── meson_options.txt        # Build-Optionen
│
├── faugus/                  # Python-Paket (Kernlogik)
│   ├── launcher.py          # Hauptfenster (Gtk.ApplicationWindow), App-ID, UI
│   ├── runner.py            # Spielprozess-Ausführung
│   ├── proton_manager.py    # Proton-Versionen verwalten
│   ├── proton_downloader.py # Proton-Download
│   ├── steam_setup.py       # Steam-Integration
│   ├── config_manager.py    # Einstellungen lesen/schreiben
│   ├── path_manager.py      # Dateipfade
│   ├── shortcut.py          # Desktop-Shortcuts erstellen
│   ├── backup.py            # Backup-Funktionalität
│   ├── gamepad.py           # Controller-Eingabe (pygame — nur joystick/event)
│   ├── keyboard.py          # Tastatureingabe
│   ├── language_config.py   # Mehrsprachigkeit
│   ├── components.py        # UI-Komponenten
│   ├── ea_fix.py            # EA-App-Kompatibilitäts-Fix
│   └── utils.py             # Hilfsfunktionen
│
├── assets/                  # Icons & Medien
│   ├── faugus-launcher.svg  # Haupt-Icon
│   ├── faugus-mono.svg      # Monochrom-Icon (Tray)
│   ├── faugus-*-symbolic.svg # Symbolische Icons (Add, Play, Stop, Kill, Settings, Exit)
│   ├── faugus-banner.png    # Banner-Bild
│   └── faugus-notification.ogg # Benachrichtigungston
│
├── data/                    # Desktop-Integration
│   ├── io.github.Faugus.faugus-launcher.desktop.in
│   ├── io.github.Faugus.faugus-launcher.shortcut.desktop.in
│   └── io.github.Faugus.faugus-launcher.metainfo.xml
│
└── languages/               # Übersetzungsdateien
```

### Technischer Stack

| Komponente | Technologie |
|---|---|
| UI-Toolkit | GTK 3.0 via PyGObject |
| Tray-Icon | AyatanaAppIndicator3 0.1 |
| Steam-Daten | `vdf`-Bibliothek |
| Bilder | Pillow (PIL) |
| Controller | pygame (nur joystick/event) |
| HTTP | requests |
| Icon-Extraktion | icoextract |
| Prozess-Infos | psutil |

---

## Abhängigkeiten

### Laufzeit — Systemseitig (müssen auf dem Zielsystem installiert sein)

| Paket | Fedora/Bazzite/Aurora | Arch/CachyOS | Zweck |
|---|---|---|---|
| `python3` (3.14) | vorinstalliert | `python` | Laufzeitumgebung |
| `python3-gobject` | `python3-gobject` | `python-gobject` | GTK3-Bindings (gi) |
| `SDL2` | `SDL2` | `sdl2` | pygame Gamepad-Support |
| GTK3 | vorinstalliert | `gtk3` | UI |

### Laufzeit — Im AppImage gebündelt

| Bibliothek | Zweck |
|---|---|
| `libayatana-appindicator3` + `libdbusmenu` | System-Tray-Icon |
| `libcanberra` + Audio-Backends | Benachrichtigungston |
| `requests`, `vdf`, `psutil`, `icoextract` | Python-Pakete (rein Python) |
| `pillow` + eigene Bildlibs | Bildverarbeitung (selbst gebündelt via `pillow.libs/`) |
| `pygame` | Gamepad-Input (SDL2 bleibt System-seitig) |

### Laufzeit (optional)

| Paket | Zweck |
|---|---|
| `vulkan-tools` | Vulkan-Support für Spiele |
| `umu-launcher` | Pflicht für die eigentliche Spielausführung |
| Steam | Für Proton-Erkennung und Steam-Spiele |

### Build-Abhängigkeiten

```
python3 (mit venv-Modul)
git
wget
rsvg-convert  (oder inkscape oder imagemagick)
```

pip wird **nicht** benötigt — das Build-Skript erstellt automatisch eine temporäre venv.

---

## Installation

### Arch Linux (AUR)

```bash
yay -S faugus-launcher
# oder
paru -S faugus-launcher
```

### Fedora / Nobara / Bazzite (COPR)

```bash
sudo dnf copr enable faugus/faugus-launcher
sudo dnf install faugus-launcher
```

### Debian / Ubuntu (PPA)

```bash
sudo add-apt-repository ppa:faugus/faugus-launcher
sudo apt update
sudo apt install faugus-launcher
```

### Flatpak (Flathub)

```bash
flatpak install flathub io.github.Faugus.faugus-launcher
```

### Aus dem Quellcode

```bash
git clone https://github.com/Faugus/faugus-launcher.git
cd faugus-launcher
meson setup build
cd build
ninja
sudo ninja install
```

---

## Verwendung

```bash
faugus-launcher
```

### Spiel hinzufügen

1. `+`-Button klicken oder Gamepad-Taste
2. Executable (`.exe`) auswählen
3. Proton-Version und Prefix-Pfad festlegen
4. Optional: Icon, Kategorie, Banner

### Standardpfade

| Zweck | Pfad |
|---|---|
| Spiel-Prefixes | `~/Faugus/` |
| Proton/Runner | `~/.local/share/Steam/compatibilitytools.d/` |
| Konfiguration | `~/.config/faugus-launcher/` |
| Logs | `~/.local/share/faugus-launcher/` |

---

## Konfiguration

Die Konfiguration erfolgt über das Settings-Fenster (Zahnrad-Icon) oder direkt in den Config-Dateien unter `~/.config/faugus-launcher/`.

### Wichtige Einstellungen

- **Standard-Proton-Version** für neue Spiele
- **Default-Prefix-Pfad**
- **Anzeigemodus** (Liste / Blöcke / Banner)
- **Autostart** beim Login
- **Steam-Bibliothek-Erkennung** aktivieren/deaktivieren

---

## Gamepad-Unterstützung

| Aktion | PlayStation | Xbox |
|---|---|---|
| Spiel starten | `×` | `A` |
| Menü öffnen | `□` | `X` |
| Einstellungen | `△` | `Y` |
| Zurück/Schließen | `○` | `B` |
| Navigation | D-Pad / Analogstick | D-Pad / Analogstick |

---

## AppImage bauen

### Voraussetzungen

Auf dem **Build-System** (Arch/CachyOS) müssen installiert sein:

```bash
# Arch/CachyOS
sudo pacman -S git wget python librsvg
```

pip muss **nicht** installiert sein — das Skript erstellt eine temporäre venv.

### Bauen

```bash
chmod +x build-faugus-appimage.sh
./build-faugus-appimage.sh
```

Das erzeugt `faugus-launcher-1.22.4-x86_64.AppImage` (~20 MB) im aktuellen Verzeichnis.

### Was das Skript tut

1. Klont das faugus-launcher Repository (`--depth=1`)
2. Erstellt eine temporäre venv und installiert alle Python-Deps mit pip ins AppDir
3. Kopiert die Anwendungsdateien und den AppRun
4. Bündelt Ayatana AppIndicator3, Dbusmenu und libcanberra
5. Baut das AppImage mit appimagetool

### Portabilität auf Fedora 44 (Bazzite / Aurora)

Das AppImage läuft auf Fedora 44-basierten Systemen, sofern folgendes installiert ist:

```bash
# Fedora / Bazzite / Aurora
sudo dnf install python3-gobject SDL2
```

| Was im AppImage gebündelt ist | Was System-seitig bleiben muss |
|---|---|
| requests, vdf, psutil, icoextract | `python3-gobject` (gi/GTK3-Bindings) |
| pillow (mit eigenen Bildlibs) | `SDL2` (für pygame Gamepad) |
| pygame (C-Extensions für Python 3.14) | GTK3 (vorinstalliert) |
| libayatana-appindicator3, libdbusmenu | — |
| libcanberra + Audio-Backends | — |

> **Hinweis:** Die pygame C-Extensions sind für **Python 3.14** kompiliert (passt zu Fedora 44, das ebenfalls Python 3.14 als Standard hat). Ältere Distros mit Python ≤ 3.13 können das AppImage nicht laden.

---

## Bekannte Einschränkungen

### Flatpak-spezifisch
- Spielprozesse können ggf. nicht korrekt beendet werden (Sandbox-Isolation)
- Gamescope-Kompatibilität eingeschränkt
- Theme-Integration abhängig vom Desktop-Environment

### Allgemein
- Benötigt `umu-launcher` zum tatsächlichen Starten von Spielen
- Proton muss separat installiert/heruntergeladen werden
- EA App / Battle.net erfordern ggf. zusätzliche Konfiguration

### AppImage (behoben in Build-Skript v1.22.4+)

| Problem | Ursache | Fix |
|---|---|---|
| „+" / „Neu"-Button tut nichts | `faugus-banner.png` lag in `assets/`-Unterordner statt direkt in `usr/share/faugus-launcher/` — `shutil.copyfile()` warf FileNotFoundError, GTK schluckte die Exception | Banner + OGG-Datei werden jetzt direkt nach `usr/share/faugus-launcher/` kopiert |
| Settings-Fenster falsch positioniert/skaliert (Aurora/KDE) | `Settings(Gtk.Dialog)` übergab den Parent nicht als `transient_for` → KWin behandelt das Fenster ohne Parent-Bezug | `super().__init__(transient_for=parent)` |
| Absturz `apply_dark_theme()` auf KDE | `Gio.Settings.new("org.gnome.desktop.interface")` schlägt fehl, wenn das GNOME-Schema nicht installiert ist | Outer try/except mit Portal-Fallback |

---

## Links

- [GitHub Repository](https://github.com/Faugus/faugus-launcher)
- [Releases](https://github.com/Faugus/faugus-launcher/releases)
- [UMU-Launcher](https://github.com/Open-Wine-Components/umu-launcher)
- [Ko-fi (Spenden)](https://ko-fi.com/Faugus)
