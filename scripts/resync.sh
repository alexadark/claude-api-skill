#!/usr/bin/env bash
# Resync reference docs from the bundled claude-api skill.
# The bundled skill lives in a version-keyed temp dir that is recreated on every
# Claude Code update, so we mirror the parts we use into this skill.
# Copies: python/ typescript/ curl/ shared/   Skips: java/ go/ ruby/ php/ csharp/
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REF_DIR="$SKILL_DIR/references"
STAMP="$REF_DIR/SOURCE.txt"

# Newest bundled copy wins, picked by directory mtime.
SRC="$(find /private/tmp/claude-*/bundled-skills -maxdepth 3 -type d -name claude-api 2>/dev/null \
  | while read -r p; do printf '%s\t%s\n' "$(stat -f %m "$p" 2>/dev/null || echo 0)" "$p"; done \
  | sort -rn | head -1 | cut -f2-)" || true

if [ -z "${SRC:-}" ] || [ ! -d "$SRC/shared" ]; then
  echo "resync: bundled claude-api not found; keeping existing references" >&2
  exit 0
fi

VERSION="$(printf '%s' "$SRC" | sed -n 's|.*/bundled-skills/\([^/]*\)/.*|\1|p')"
PREV="$(sed -n 's/^version: //p' "$STAMP" 2>/dev/null || true)"

if [ "$VERSION" = "$PREV" ] && [ "${1:-}" != "--force" ]; then
  exit 0  # already current
fi

mkdir -p "$REF_DIR"
for d in python typescript curl shared; do
  [ -d "$SRC/$d" ] || continue
  rm -rf "$REF_DIR/$d"
  cp -R "$SRC/$d" "$REF_DIR/$d"
done

cat > "$STAMP" <<EOF
version: $VERSION
synced: $(date -u +%Y-%m-%dT%H:%M:%SZ)
source: $SRC
copied: python typescript curl shared
skipped: java go ruby php csharp
EOF

echo "resync: claude-api references updated to $VERSION" >&2
