#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# ── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*"; }
die()  { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

echo ""
echo "Log Your Dog — local setup"
echo "──────────────────────────"

# ── 1. Check required tools ───────────────────────────────────────────────────
echo ""
echo "Checking prerequisites..."

command -v flutter >/dev/null 2>&1 || die "flutter not found. Install from https://docs.flutter.dev/get-started/install"
ok "flutter $(flutter --version --machine 2>/dev/null | grep -o '"frameworkVersion":"[^"]*"' | cut -d'"' -f4 || echo '(version unknown)')"

command -v node >/dev/null 2>&1 || die "node not found. Install from https://nodejs.org"
ok "node $(node --version)"

command -v npm >/dev/null 2>&1 || die "npm not found. Install from https://nodejs.org"
ok "npm $(npm --version)"

# ── 2. Install firebase-tools if missing ──────────────────────────────────────
echo ""
echo "Checking firebase-tools..."

if ! command -v firebase >/dev/null 2>&1; then
  warn "firebase-tools not found — installing globally..."
  npm install -g firebase-tools
  ok "firebase-tools installed"
else
  ok "firebase $(firebase --version)"
fi

# ── 3. Copy example config files (skip if already present) ───────────────────
echo ""
echo "Setting up config files..."

copy_if_missing() {
  local src="$1" dst="$2"
  if [ -f "$dst" ]; then
    warn "$dst already exists — skipping"
  else
    cp "$src" "$dst"
    ok "Created $dst"
  fi
}

copy_if_missing firebase.json.example   firebase.json
copy_if_missing .firebaserc.example     .firebaserc
mkdir -p .vscode
copy_if_missing .vscode/launch.json.example .vscode/launch.json

# ── 4. Flutter dependencies ───────────────────────────────────────────────────
echo ""
echo "Installing Flutter dependencies..."
flutter pub get
ok "flutter pub get done"

# ── 5. Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}Setup complete.${NC}"
echo ""
echo "Next steps:"
echo "  1. Start the Firebase emulator:"
echo "       firebase emulators:start"
echo ""
echo "  2. In a separate terminal, run the app:"
echo "       flutter run --dart-define=USE_EMULATOR=true"
echo ""
echo "  Emulator UI → http://localhost:4000"
echo ""
echo "For production, fill in your Firebase values in .vscode/launch.json"
echo "(see .vscode/launch.json.example for the required --dart-define keys)."
echo ""
