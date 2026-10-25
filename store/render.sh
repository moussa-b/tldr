#!/usr/bin/env bash
# Renders the store visuals from the screenshots in store/raw/<lang>/ with
# store/template.html and headless Chrome, at the exact store sizes.
#
#   store/render.sh
#
# Output: store/app-store/<lang>/{iphone-6.9,ipad-13}/ and store/google-play/.
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

# Each slide: screenshot name in raw/<lang>/<device>-<name>.png, title, subtitle.
slides_fr=(
  "summary|Un thread entier, lu pour toi|Le résumé, les points de vue et le ton de la discussion, en quelques secondes."
  "dust|Le post se dissout en résumé|TL;DR+ lit le thread directement sur Reddit, puis ton IA écrit."
  "verdict|Sentiment, émotions, toxicité|Et l'avis de l'IA sur ce que la discussion dit vraiment."
  "home|Tous tes résumés au même endroit|Partage un post depuis Reddit, ou colle son lien."
  "settings|Ta clé, ton IA|Gemini, Claude ou OpenAI. Ta clé reste sur ton téléphone."
)
slides_en=(
  "summary|A whole thread, read for you|The summary, the viewpoints and the tone of the discussion, in seconds."
  "dust|The post dissolves into a summary|TL;DR+ reads the thread right on Reddit, then your AI writes."
  "verdict|Sentiment, emotions, toxicity|Plus the AI's take on what the discussion really says."
  "home|All your summaries in one place|Share a post from Reddit, or paste its link."
  "settings|Your key, your AI|Gemini, Claude or OpenAI. Your key stays on your phone."
)

for lang in fr en; do
  slides_var="slides_${lang}[@]"
  n=0
  for slide in "${!slides_var}"; do
    IFS='|' read -r name title sub <<<"$slide"
    n=$((n + 1))
    raw=raw/$lang
    [[ -f $raw/iphone-$name.png ]] && render "app-store/$lang/iphone-6.9/0$n-$name.png" 1320 2868 "$raw/iphone-$name.png" "$title" "$sub"
    [[ -f $raw/ipad-$name.png ]] && render "app-store/$lang/ipad-13/0$n-$name.png" 2064 2752 "$raw/ipad-$name.png" "$title" "$sub" 74
    # The Play listing is French only.
    [[ $lang == fr && -f $raw/android-$name.png ]] && render "google-play/phone/0$n-$name.png" 1080 1920 "$raw/android-$name.png" "$title" "$sub" 74
  done
done

render google-play/feature-graphic.png 1024 500 ../assets/icon/icon.png \
  "TL;DR+" "Le résumé de n'importe quel thread Reddit, avec ta propre IA." 0 1
sips -z 512 512 ../assets/icon/icon.png --out google-play/icon-512.png >/dev/null
echo "google-play/icon-512.png 512x512"
