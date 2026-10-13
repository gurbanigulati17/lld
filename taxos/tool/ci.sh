#!/usr/bin/env bash
# One command that runs everything CI runs. Usage:
#   tool/ci.sh            # analyze + test every package
#   tool/ci.sh engine     # only the pure-Dart engine (fast, no Flutter needed)
#   tool/ci.sh build      # also build the web app
set -euo pipefail
cd "$(dirname "$0")/.."

scope="${1:-all}"

have_flutter() { command -v flutter >/dev/null 2>&1; }

run_engine() {
  echo "== tax_engine"
  (cd packages/tax_engine && dart pub get >/dev/null && dart analyze --fatal-infos && dart test --reporter compact)
  echo "== services/api"
  (cd services/api && dart pub get >/dev/null && dart analyze --fatal-infos && dart test --reporter compact)
}

run_flutter() {
  if ! have_flutter; then
    echo "flutter not on PATH; skipping glass_ui and taxos_app (run tool/ci.sh engine for Dart-only checks)" >&2
    return 1
  fi
  flutter pub get >/dev/null
  echo "== glass_ui"
  (cd packages/glass_ui && flutter analyze --fatal-infos && flutter test --reporter compact)
  echo "== taxos_app"
  (cd apps/taxos_app && flutter analyze --fatal-infos && flutter test --reporter compact)
}

case "$scope" in
  engine) run_engine ;;
  all) run_engine; run_flutter ;;
  build)
    run_engine; run_flutter
    echo "== taxos_app web build"
    (cd apps/taxos_app && flutter build web --release)
    ;;
  *) echo "unknown scope: $scope" >&2; exit 2 ;;
esac
echo "CI OK ($scope)"
