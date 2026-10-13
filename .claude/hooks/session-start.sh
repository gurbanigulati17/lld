#!/bin/bash
# SessionStart hook: make Dart and Flutter available in Claude Code cloud
# sessions so tests, analysis and builds for taxos/ work out of the box.
# Local sessions are left untouched.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/.flutter-sdk/flutter}"
FLUTTER_CHANNEL_JSON="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"

if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  echo "[session-start] installing Flutter stable into $FLUTTER_ROOT"
  mkdir -p "$(dirname "$FLUTTER_ROOT")"
  archive=$(curl -fsSL "$FLUTTER_CHANNEL_JSON" | python3 -c '
import json, sys
d = json.load(sys.stdin)
h = d["current_release"]["stable"]
print(next(r["archive"] for r in d["releases"] if r["hash"] == h))')
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/flutter.tar.xz" "https://storage.googleapis.com/flutter_infra_release/releases/$archive"
  tar -xJf "$tmp/flutter.tar.xz" -C "$(dirname "$FLUTTER_ROOT")"
  rm -rf "$tmp"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_ROOT" >/dev/null 2>&1 || true
flutter config --no-analytics --enable-web >/dev/null 2>&1 || true
flutter precache --web >/dev/null 2>&1 || true

# Persist PATH for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_ROOT/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
  echo "export FLUTTER_ROOT=\"$FLUTTER_ROOT\"" >> "$CLAUDE_ENV_FILE"
fi

# Resolve the workspace once so analyze/test start instantly.
cd "$CLAUDE_PROJECT_DIR/taxos"
flutter pub get >/dev/null
echo "[session-start] $(flutter --version 2>/dev/null | head -1)"
echo "[session-start] taxos workspace ready: run taxos/tool/ci.sh"
