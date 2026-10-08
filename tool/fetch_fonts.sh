#!/usr/bin/env bash
# Bundles IBM Plex Sans and Literata (DESIGN.md) so google_fonts never fetches
# them at runtime. google_fonts picks up matching files in assets/google_fonts/.
# Fonts are under the SIL Open Font License (copied next to the files).
set -euo pipefail
cd "$(dirname "$0")/.."
dest=assets/google_fonts
mkdir -p "$dest"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/plex.zip" "https://github.com/IBM/plex/releases/download/%40ibm%2Fplex-sans%401.1.0/ibm-plex-sans.zip"
unzip -q "$tmp/plex.zip" -d "$tmp/plex"
for w in Regular Medium SemiBold; do
  cp "$(find "$tmp/plex" -name "IBMPlexSans-$w.ttf" | head -1)" "$dest/IBMPlexSans-$w.ttf"
done
cp "$(find "$tmp/plex" -iname 'LICENSE*' | head -1)" "$dest/OFL-IBMPlexSans.txt"
echo "Literata: download the static TTFs from https://fonts.google.com/specimen/Literata"
echo "and copy Literata-Regular.ttf, Literata-Italic.ttf, Literata-SemiBold.ttf into $dest/."
