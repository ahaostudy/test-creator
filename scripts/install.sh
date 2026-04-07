#!/usr/bin/env bash
set -euo pipefail

# test-creator installer
# Supports two modes:
#   1. From repo:  ./install.sh --tool <tool>
#   2. Remote:     curl -sSL .../install.sh | bash -s -- --tool <tool>

SKILL_NAME="test-creator"
REPO_URL="https://github.com/ahaostudy/test-creator.git"

# --- Parse args ---
TOOL=""
CUSTOM_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)    TOOL="$2"; shift 2 ;;
    --dir)     CUSTOM_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: ./install.sh --tool <claude-code|codex|openclaw|generic> [--dir <path>]"
      echo ""
      echo "Options:"
      echo "  --tool      Target tool: claude-code, codex, openclaw, generic"
      echo "  --dir       Custom target directory (only for --tool generic)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$TOOL" ]]; then
  echo "Error: --tool is required"
  echo "Run ./install.sh --help for usage"
  exit 1
fi

# --- Resolve source: local repo or remote clone ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}" 2>/dev/null)"/.. && pwd 2>/dev/null || echo "")"
TMP_CLONE=""

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/SKILL.md" ]]; then
  REPO_ROOT="$SCRIPT_DIR"
else
  # Running via pipe (curl | bash), need to clone
  TMP_CLONE="$(mktemp -d)"
  echo "Downloading test-creator..."
  git clone --depth 1 "$REPO_URL" "$TMP_CLONE/test-creator" >/dev/null 2>&1
  REPO_ROOT="$TMP_CLONE/test-creator"
fi

cleanup() {
  [[ -n "$TMP_CLONE" && -d "$TMP_CLONE" ]] && rm -rf "$TMP_CLONE"
}
trap cleanup EXIT

# --- Resolve target directory ---
resolve_target() {
  case "$TOOL" in
    claude-code)
      echo "$HOME/.claude/skills/$SKILL_NAME"
      ;;
    codex)
      echo "$HOME/.agents/skills/$SKILL_NAME"
      ;;
    openclaw)
      echo "$HOME/.agents/skills/$SKILL_NAME"
      ;;
    generic)
      if [[ -z "$CUSTOM_DIR" ]]; then
        echo "Error: --dir is required for --tool generic"
        exit 1
      fi
      echo "$CUSTOM_DIR/$SKILL_NAME"
      ;;
    *)
      echo "Error: Unknown tool '$TOOL'"
      echo "Supported: claude-code, codex, openclaw, generic"
      exit 1
      ;;
  esac
}

TARGET="$(resolve_target)"

# --- Install ---
echo "Installing test-creator to: $TARGET"

mkdir -p "$TARGET"

# Copy files preserving directory structure
cp "$REPO_ROOT/SKILL.md" "$TARGET/"
cp -r "$REPO_ROOT/adapters" "$TARGET/"
cp -r "$REPO_ROOT/scripts" "$TARGET/"
cp -r "$REPO_ROOT/references" "$TARGET/"

# Make shell scripts executable
find "$TARGET" -name "*.sh" -exec chmod +x {} \;

echo ""
echo "Done! Installed files:"
echo "  $TARGET/SKILL.md"
echo "  $TARGET/adapters/   ($(ls "$TARGET/adapters/" | wc -l | tr -d ' ') files)"
echo "  $TARGET/scripts/    ($(ls "$TARGET/scripts/" | wc -l | tr -d ' ') files)"
echo "  $TARGET/references/ ($(ls "$TARGET/references/" | wc -l | tr -d ' ') files)"
echo ""
echo "test-creator is ready to use."
