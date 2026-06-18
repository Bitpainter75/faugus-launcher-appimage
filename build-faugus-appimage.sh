#!/bin/bash
set -e

# Build script for faugus-launcher AppImage
# Requires: wget, python3, git
# Target: x86_64 Linux

APPDIR="$(pwd)/AppDir"
VERSION="1.22.4"
ARCH="x86_64"
OUTPUT="faugus-launcher-${VERSION}-${ARCH}.AppImage"

APPIMAGETOOL="$(pwd)/appimagetool-${ARCH}.AppImage"
LINUXDEPLOY="$(pwd)/linuxdeploy-${ARCH}.AppImage"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Temporäre venv als pip-Umgebung: umgeht PEP 668 (externally-managed-environment)
# auf Arch/CachyOS und funktioniert ohne systemweit installierten pip.
VENV_DIR="$(mktemp -d /tmp/faugus-build-venv-XXXXXX)"
python3 -m venv "$VENV_DIR"
PIP="$VENV_DIR/bin/pip"
trap 'rm -rf "$VENV_DIR"; exit' INT TERM

# ── 1. Tools herunterladen ────────────────────────────────────────────────────

info "Lade Build-Tools herunter..."

if [ ! -f "$APPIMAGETOOL" ]; then
    wget -q --show-progress \
        "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage" \
        -O "$APPIMAGETOOL"
    chmod +x "$APPIMAGETOOL"
fi

if [ ! -f "$LINUXDEPLOY" ]; then
    wget -q --show-progress \
        "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage" \
        -O "$LINUXDEPLOY"
    chmod +x "$LINUXDEPLOY"
fi

# ── 2. Quellcode holen ───────────────────────────────────────────────────────

if [ ! -d "faugus-launcher-src" ]; then
    info "Klone Repository..."
    git clone --depth=1 https://github.com/Faugus/faugus-launcher.git faugus-launcher-src
else
    info "Repository bereits vorhanden, überspringe Clone."
fi

SRC="$(pwd)/faugus-launcher-src"

# ── 3. AppDir-Struktur erstellen ─────────────────────────────────────────────

info "Erstelle AppDir-Struktur..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib/python3/dist-packages"
mkdir -p "$APPDIR/usr/share/faugus-launcher"
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/apps"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$APPDIR/usr/share/applications"

# ── 4. Python-Abhängigkeiten ins AppDir installieren ─────────────────────────

info "Installiere Python-Abhängigkeiten ins AppDir..."
PYDIR="$APPDIR/usr/lib/python3/site-packages"
mkdir -p "$PYDIR"

# Pakete einzeln installieren für bessere Fehlerdiagnose.
# pygame und pillow haben C-Erweiterungen — mit Deps installieren damit
# transitive native Libs (SDL2 etc.) mitgenommen werden.
# pygobject wird NICHT gebundelt (bindet tief ins Desktop-GTK ein).
for pkg in requests vdf psutil icoextract; do
    info "  pip: $pkg"
    $PIP install --target="$PYDIR" --no-deps "$pkg" --quiet \
        || warn "  FEHLGESCHLAGEN: $pkg"
done
for pkg in pillow pygame; do
    info "  pip (mit Deps): $pkg"
    $PIP install --target="$PYDIR" "$pkg" --quiet \
        || warn "  FEHLGESCHLAGEN: $pkg"
done

# ── 5. Anwendungsdateien kopieren ────────────────────────────────────────────

info "Kopiere Anwendungsdateien..."

# Hauptskript
cp "$SRC/faugus-launcher" "$APPDIR/usr/bin/faugus-launcher"
cp "$SRC/faugus_run.py"   "$APPDIR/usr/bin/faugus-run"
chmod +x "$APPDIR/usr/bin/faugus-launcher"
chmod +x "$APPDIR/usr/bin/faugus-run"

# Python-Paket
cp -r "$SRC/faugus" "$APPDIR/usr/share/faugus-launcher/"

# Assets
cp -r "$SRC/assets" "$APPDIR/usr/share/faugus-launcher/"

# Sprachen
if [ -d "$SRC/languages" ]; then
    cp -r "$SRC/languages" "$APPDIR/usr/share/faugus-launcher/"
fi

# ── 6. Icon ──────────────────────────────────────────────────────────────────

info "Setze Icons..."
cp "$SRC/assets/faugus-launcher.svg" \
   "$APPDIR/usr/share/icons/hicolor/scalable/apps/faugus-launcher.svg"
cp "$SRC/assets/faugus-launcher.svg" \
   "$APPDIR/faugus-launcher.svg"

# Symbolische Action-Icons ins GTK-Icon-Theme-Verzeichnis kopieren.
# GTK sucht Gtk.Image.new_from_icon_name() unter XDG_DATA_DIRS/icons/hicolor/scalable/actions/.
# Ohne diesen Schritt fehlen die Button-Grafiken auf Systemen ohne System-Installation (z.B. Bazzite/Aurora).
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/actions"
for svg in faugus-add-symbolic faugus-exit-symbolic faugus-kill-symbolic \
           faugus-play-symbolic faugus-settings-symbolic faugus-stop-symbolic; do
    cp "$SRC/assets/${svg}.svg" \
       "$APPDIR/usr/share/icons/hicolor/scalable/actions/${svg}.svg"
    info "  Action-Icon: ${svg}.svg"
done

# PNG-Icon generieren (256x256) falls inkscape oder rsvg-convert vorhanden
if command -v rsvg-convert &>/dev/null; then
    rsvg-convert -w 256 -h 256 \
        "$SRC/assets/faugus-launcher.svg" \
        -o "$APPDIR/usr/share/icons/hicolor/256x256/apps/faugus-launcher.png"
    cp "$APPDIR/usr/share/icons/hicolor/256x256/apps/faugus-launcher.png" \
       "$APPDIR/faugus-launcher.png"
elif command -v inkscape &>/dev/null; then
    inkscape --export-type=png --export-width=256 --export-height=256 \
        --export-filename="$APPDIR/usr/share/icons/hicolor/256x256/apps/faugus-launcher.png" \
        "$SRC/assets/faugus-launcher.svg" 2>/dev/null
    cp "$APPDIR/usr/share/icons/hicolor/256x256/apps/faugus-launcher.png" \
       "$APPDIR/faugus-launcher.png"
elif command -v convert &>/dev/null; then
    convert "$SRC/assets/faugus-launcher.svg" \
        -resize 256x256 \
        "$APPDIR/usr/share/icons/hicolor/256x256/apps/faugus-launcher.png"
    cp "$APPDIR/usr/share/icons/hicolor/256x256/apps/faugus-launcher.png" \
       "$APPDIR/faugus-launcher.png"
else
    warn "Kein SVG→PNG-Konverter gefunden (rsvg-convert/inkscape/convert). Nutze SVG direkt."
fi

# ── 7. .desktop-Datei ────────────────────────────────────────────────────────

info "Erstelle .desktop-Datei..."
cat > "$APPDIR/faugus-launcher.desktop" << 'DESKTOP'
[Desktop Entry]
Name=Faugus Launcher
GenericName=Game Launcher
Comment=Simple and lightweight app for running Windows games using UMU-Launcher
Exec=faugus-launcher %U
Icon=faugus-launcher
Type=Application
Categories=Game;
Keywords=gaming;proton;wine;launcher;umu;
StartupNotify=true
DESKTOP

cp "$APPDIR/faugus-launcher.desktop" \
   "$APPDIR/usr/share/applications/faugus-launcher.desktop"

# ── 8. AppRun ────────────────────────────────────────────────────────────────

info "Erstelle AppRun..."
cat > "$APPDIR/AppRun" << 'APPRUN'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE="${SELF%/*}"

# Eigene Binaries bevorzugen
export PATH="${HERE}/usr/bin:${PATH}"

# Python-Module aus dem AppDir einbinden
export PYTHONPATH="${HERE}/usr/lib/python3/site-packages:${HERE}/usr/share/faugus-launcher:${PYTHONPATH}"

# Native Bibliotheken (Ayatana + Dbusmenu + Canberra werden aus dem AppDir geladen)
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"

# GObject Introspection: gebundelte Typelibs vor System-Typelibs bevorzugen
export GI_TYPELIB_PATH="${HERE}/usr/lib/girepository-1.0:${GI_TYPELIB_PATH}"

# libltdl Plugin-Suchpfad für libcanberra Audio-Backends (Pulse, ALSA etc.)
export LTDL_LIBRARY_PATH="${HERE}/usr/lib/libcanberra-0.30:${LTDL_LIBRARY_PATH}"

# XDG-Datenverzeichnisse (Icons, Themes)
export XDG_DATA_DIRS="${HERE}/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# Faugus-Datenpfad
export FAUGUS_DATA_DIR="${HERE}/usr/share/faugus-launcher"

exec "${HERE}/usr/bin/faugus-launcher" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# ── 9. Python-Suchpfad im Hauptskript patchen ────────────────────────────────

info "Patche faugus-launcher Skript..."
# Das installierte faugus-launcher-Skript sucht das faugus-Paket über sys.path.
# Wir stellen sicher, dass der AppDir-Pfad korrekt aufgelöst wird.
# Die AppRun setzt PYTHONPATH bereits — das genügt für Python-Importe.
# Falls das Skript absolute Pfade für assets/languages nutzt, patchen wir das:
if grep -q '/usr/share/faugus' "$APPDIR/usr/bin/faugus-launcher" 2>/dev/null; then
    warn "Skript enthält hardcodierte Pfade — ggf. manuell anpassen."
fi

# ── 10. AyatanaAppIndicator3 + Dbusmenu bundeln ──────────────────────────────

info "Bundele AyatanaAppIndicator3 und Dbusmenu..."

APPDIR_LIB="$APPDIR/usr/lib"
APPDIR_TYPELIB="$APPDIR/usr/lib/girepository-1.0"
TYPELIBDIR="/usr/lib/girepository-1.0"
mkdir -p "$APPDIR_TYPELIB"

# Native .so-Dateien (nur Ayatana-spezifisch; GTK/glib bleiben System-seitig)
AYATANA_LIBS=(
    "libayatana-appindicator3.so.1.0.0"
    "libayatana-indicator3.so.7.0.0"
    "libayatana-ido3-0.4.so.0.0.0"
    "libdbusmenu-glib.so.4.0.12"
    "libdbusmenu-gtk3.so.4.0.12"
)

for sofile in "${AYATANA_LIBS[@]}"; do
    src=$(find /usr/lib -name "$sofile" 2>/dev/null | head -1)
    if [ -n "$src" ]; then
        cp "$src" "$APPDIR_LIB/"
        # Versionierte Symlinks anlegen (z.B. .so.1 → .so.1.0.0)
        base="${sofile%.0}"          # libayatana-appindicator3.so.1.0
        base2="${base%.0}"           # libayatana-appindicator3.so.1
        base3="${base2%.[0-9]*}"     # libayatana-appindicator3.so  (nur wenn major != 0)
        for sym in "$base" "$base2" "$base3"; do
            [ "$sym" != "$sofile" ] && [ -n "$sym" ] && \
                ln -sf "$sofile" "$APPDIR_LIB/$sym" 2>/dev/null || true
        done
        info "  Kopiert: $sofile"
    else
        warn "  Nicht gefunden: $sofile"
    fi
done

# GI Typelibs (was gi.repository zum Laden der Bindings braucht)
AYATANA_TYPELIBS=(
    "AyatanaAppIndicator3-0.1.typelib"
    "AyatanaIdo3-0.4.typelib"
    "Dbusmenu-0.4.typelib"
    "DbusmenuGtk3-0.4.typelib"
)

# Explizite SONAME-Symlinks für dbusmenu — Versionsnummer endet auf .12, nicht .0,
# daher greift der generische Symlink-Algorithmus oben nicht.
ln -sf "libdbusmenu-glib.so.4.0.12"  "$APPDIR_LIB/libdbusmenu-glib.so.4"
ln -sf "libdbusmenu-gtk3.so.4.0.12"  "$APPDIR_LIB/libdbusmenu-gtk3.so.4"
info "  Symlink: libdbusmenu-glib.so.4 + libdbusmenu-gtk3.so.4"

for tl in "${AYATANA_TYPELIBS[@]}"; do
    if [ -f "${TYPELIBDIR}/${tl}" ]; then
        cp "${TYPELIBDIR}/${tl}" "$APPDIR_TYPELIB/"
        info "  Typelib: $tl"
    else
        warn "  Typelib nicht gefunden: $tl"
    fi
done

# ── 11. libcanberra + canberra-gtk-play bundeln ──────────────────────────────

info "Bundele libcanberra..."

# Binary (wird von faugus als Subprocess aufgerufen)
cp /usr/bin/canberra-gtk-play "$APPDIR/usr/bin/"

# Canberra-spezifische Libs (GTK/glib/X11 bleiben System-seitig)
CANBERRA_LIBS=(
    "libcanberra.so.0.2.5"
    "libcanberra-gtk3.so.0.1.9"
    "libvorbisfile.so.3"
    "libvorbis.so.0"
    "libogg.so.0"
    "libtdb.so.1"
    "libltdl.so.7"
)

for sofile in "${CANBERRA_LIBS[@]}"; do
    src=$(find /usr/lib -name "$sofile" 2>/dev/null | head -1)
    if [ -n "$src" ]; then
        cp "$src" "$APPDIR_LIB/"
        # Versionierten Symlink anlegen (z.B. libfoo.so.0 → libfoo.so.0.2.5)
        sym="${sofile%.*.*}"   # libcanberra.so.0
        [ "$sym" != "$sofile" ] && ln -sf "$sofile" "$APPDIR_LIB/$sym" 2>/dev/null || true
        sym2="${sym%.*}"       # libcanberra.so
        [ "$sym2" != "$sym" ] && ln -sf "$sofile" "$APPDIR_LIB/$sym2" 2>/dev/null || true
        info "  Kopiert: $sofile"
    else
        warn "  Nicht gefunden: $sofile"
    fi
done

# Audio-Backend-Plugins (Pulse, ALSA etc.) — werden von libltdl dynamisch geladen
CANBERRA_PLUGIN_DIR="$APPDIR/usr/lib/libcanberra-0.30"
mkdir -p "$CANBERRA_PLUGIN_DIR"
if [ -d "/usr/lib/libcanberra-0.30" ]; then
    cp /usr/lib/libcanberra-0.30/*.so "$CANBERRA_PLUGIN_DIR/" 2>/dev/null || true
    info "  Plugins kopiert: $(ls "$CANBERRA_PLUGIN_DIR" | tr '\n' ' ')"
else
    warn "  Plugin-Verzeichnis /usr/lib/libcanberra-0.30 nicht gefunden"
fi

# ── 12. AppImage zusammenbauen ────────────────────────────────────────────────

info "Baue AppImage..."
ARCH="${ARCH}" "$APPIMAGETOOL" \
    "$APPDIR" \
    "$OUTPUT"

info ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "Fertig: ${OUTPUT}"
info "Ausführen mit: ./${OUTPUT}"
info ""
warn "Hinweis: GTK3 muss auf dem Zielsystem vorhanden sein."
warn "AyatanaAppIndicator3, Dbusmenu und libcanberra sind gebundelt."
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
