#!/usr/bin/env bash
# Renders the store visuals from the screenshots in store/raw/ with
# store/template.html and headless Chrome, at the exact store sizes.
#
#   store/render.sh
#
# Output: store/app-store/{iphone-6.9,ipad-13}/ and store/google-play/.
set -euo pipefail
cd "$(dirname "$0")"
chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# render <out.png> <width> <height> <screenshot> <title> <subtitle> [shot width %] [banner]
render() {
  local out=$1 w=$2 h=$3 img=$4 title=$5 sub=$6 shot=${7:-78} banner=${8:-}
  local query
  query=$(python3 -c 'import sys, urllib.parse as u; print(u.urlencode({"w": sys.argv[1], "h": sys.argv[2], "img": sys.argv[3], "t": sys.argv[4], "s": sys.argv[5], "shot": sys.argv[6], "banner": sys.argv[7]}))' \
    "$w" "$h" "$img" "$title" "$sub" "$shot" "$banner")
  mkdir -p "$(dirname "$out")"
  "$chrome" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=3000 \
    --window-size="$w,$h" --screenshot="$PWD/$out" "file://$PWD/template.html?$query" >/dev/null 2>&1
  # Stores reject transparency in screenshots and the feature graphic.
  sips -s format png -s formatOptions default "$out" >/dev/null
  echo "$out ${w}x${h}"
}

# Each slide: screenshot name in raw/<device>-<name>.png, title, subtitle.
slides=(
  "summary-fr|Un thread entier, lu pour toi|Le résumé, les points de vue et le ton de la discussion, en quelques secondes."
  "dust|Le post se dissout en résumé|TL;DR+ lit le thread directement sur Reddit, puis ton IA écrit."
  "verdict|Sentiment, émotions, toxicité|Et l'avis de l'IA sur ce que la discussion dit vraiment."
  "home|Tous tes résumés au même endroit|Partage un post depuis Reddit, ou colle son lien."
  "settings|Ta clé, ton IA|Gemini, Claude ou OpenAI. Ta clé reste sur ton téléphone."
)

n=0
for slide in "${slides[@]}"; do
  IFS='|' read -r name title sub <<<"$slide"
  n=$((n + 1))
  [[ -f raw/iphone-$name.png ]] && render "app-store/iphone-6.9/0$n-$name.png" 1320 2868 "raw/iphone-$name.png" "$title" "$sub"
  [[ -f raw/ipad-$name.png ]] && render "app-store/ipad-13/0$n-$name.png" 2064 2752 "raw/ipad-$name.png" "$title" "$sub" 74
  [[ -f raw/android-$name.png ]] && render "google-play/phone/0$n-$name.png" 1080 1920 "raw/android-$name.png" "$title" "$sub" 74
done

render google-play/feature-graphic.png 1024 500 ../assets/icon/icon.png \
  "TL;DR+" "Le résumé de n'importe quel thread Reddit, avec ta propre IA." 0 1
sips -z 512 512 ../assets/icon/icon.png --out google-play/icon-512.png >/dev/null
echo "google-play/icon-512.png 512x512"
