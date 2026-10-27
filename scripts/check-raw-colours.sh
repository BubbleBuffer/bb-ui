#!/usr/bin/env bash
# Fails when UI code writes a raw colour. Every colour comes from the
# generated palette (packages/bb_tokens/lib/src/colors.g.dart, see
# packages/bb_tokens/README.md); widgets read AppTheme roles or AppColors.
#
# Checked: packages/bb_ui and apps/. Not checked: generated
# files (*.g.dart), tests (test/ folders) and packages/bb_tokens itself, which
# is where the few base constants (kTransparent, kMaskOpaque) live.
# Colors.transparent is Material and not used; kTransparent is the UI name.
#
# Usage: scripts/check-raw-colours.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

pattern='Color[[:space:]]*\([[:space:]]*(0x|[0-9])|Color\.fromARGB|Color\.fromRGBO|Color\.from\('
hits=$(
  while IFS= read -r -d '' file; do
    case "$file" in
      *.g.dart|*/test/*) continue ;;
      *.dart) [[ -f "$file" ]] && grep -nHE "$pattern" -- "$file" || true ;;
    esac
  done < <(git ls-files -z --cached --others --exclude-standard -- packages/bb_ui apps)
)

if [[ -n $hits ]]; then
  echo "Raw colours in UI code (use AppTheme or a palette role instead):" >&2
  echo "$hits" >&2
  exit 1
fi
echo "No raw colours in packages/bb_ui or apps/."
