#!/usr/bin/env bash
# Real summary on a simulator or emulator (tool/live_summary/main.dart).
#
#   tool/live_summary.sh <device-id> [extra flutter run args]
#
# Keys come from gemini.keys at the repo root (one per line, git-ignored).
# Prints the LIVE_* lines and exits 0 on LIVE_OK, 1 otherwise.
set -euo pipefail
cd "$(dirname "$0")/.."

device="${1:?usage: tool/live_summary.sh <device-id> [flutter run args]}"
shift
[[ -f gemini.keys ]] || { echo "LIVE_FAIL gemini.keys missing"; exit 1; }
keys=$(grep -v '^\s*$' gemini.keys | tr -d ' \r' | paste -sd, -)

log=$(mktemp -t live_summary)
fvm flutter run -d "$device" -t tool/live_summary/main.dart \
  --dart-define=GEMINI_KEYS="$keys" "$@" >"$log" 2>&1 </dev/null &
pid=$!

status=1
for _ in $(seq 1 600); do
  if grep -q 'LIVE_OK\|LIVE_FAIL' "$log"; then
    sleep 1
    grep -q 'LIVE_OK' "$log" && status=0
    break
  fi
  if ! kill -0 "$pid" 2>/dev/null; then
    tail -20 "$log"
    break
  fi
  sleep 1
done

kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true
grep -o 'LIVE_[A-Z]*.*' "$log" || echo "LIVE_FAIL no result (log: $log)"
[[ $status == 0 ]] && rm -f "$log"
exit $status
