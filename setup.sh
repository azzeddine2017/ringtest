#!/usr/bin/env bash
set -e

echo "Installing ringtest locally..."

# Detect Ring bin directory or fallback to local bin
if [ -n "$RINGPATH" ] && [ -d "$RINGPATH/bin" ]; then
    TARGET_DIR="$RINGPATH/bin"
elif command -v ring >/dev/null 2>&1; then
    TARGET_DIR="$(dirname "$(command -v ring)")"
else
    TARGET_DIR="/usr/local/bin"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_FILE="$TARGET_DIR/ringtest"

cat << EOF > "$TARGET_FILE"
#!/usr/bin/env bash
export RINGTEST_CALLER_DIR="\$(pwd)"
cd "$SCRIPT_DIR"
ring "main.ring" "\$@"
EOF

chmod +x "$TARGET_FILE"

echo "ringtest wrapper created at: $TARGET_FILE"
echo "You can now use 'ringtest' globally from any terminal!"