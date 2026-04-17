#!/usr/bin/env bash
set -euo pipefail

# One-click deploy all local skills to Codex runtime location.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT_DIR}/skills"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
TARGET_DIR="${CODEX_HOME_DIR}/skills"
MODE="copy"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/deploy-skills.sh [--copy|--link]

Options:
  --copy   Copy each skill directory into CODEX_HOME/skills (default).
  --link   Create/update symlinks instead of copying.
  --help   Show this help.

Environment:
  CODEX_HOME   Override Codex home, defaults to $HOME/.codex
USAGE
}

if [[ $# -gt 2 ]]; then
  echo "Error: too many arguments." >&2
  usage
  exit 1
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    --copy)
      MODE="copy"
      ;;
    --link)
      MODE="link"
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option '$1'" >&2
      usage
      exit 1
      ;;
  esac
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "Error: skills directory not found: $SKILLS_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

shopt -s nullglob
SKILL_PATHS=("$SKILLS_DIR"/*/)
if (( ${#SKILL_PATHS[@]} == 0 )); then
  echo "No skill directories found in $SKILLS_DIR"
  exit 0
fi

deploy_one() {
  local source_dir="$1"
  local name
  name="$(basename "$source_dir")"
  local dest_dir="${TARGET_DIR}/${name}"

  if [[ "$MODE" == "link" ]]; then
    ln -sfn "$source_dir" "$dest_dir"
    echo "Linked: $dest_dir"
  else
    rm -rf "$dest_dir"
    cp -R "$source_dir" "$TARGET_DIR"
    echo "Copied: $name"
  fi
}

for skill_dir in "${SKILL_PATHS[@]}"; do
  deploy_one "$skill_dir"
done

echo "Done. CODEX skills deployed to: ${TARGET_DIR}"
echo "Mode: ${MODE}"
