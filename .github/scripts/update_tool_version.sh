#!/bin/bash
set -euo pipefail

# Script to update a single tool version in .tool-versions file
# Usage: update-tool-version.sh <tool-name> <new-version> [tool-versions-file]

TOOL_NAME="$1"
NEW_VERSION="$2"
TOOL_VERSIONS_FILE="${3:-.tool-versions}"

if [[ ! -f "$TOOL_VERSIONS_FILE" ]]; then
  echo "Error: $TOOL_VERSIONS_FILE not found"
  exit 1
fi

# Create a backup
cp "$TOOL_VERSIONS_FILE" "${TOOL_VERSIONS_FILE}.bak"

# Update the version using awk
awk -v tool="$TOOL_NAME" -v version="$NEW_VERSION" '
  $1 == tool {
    print tool " " version
    next
  }
  {print}
' "${TOOL_VERSIONS_FILE}.bak" > "$TOOL_VERSIONS_FILE"

# Remove backup
rm "${TOOL_VERSIONS_FILE}.bak"

echo "Updated $TOOL_NAME to $NEW_VERSION in $TOOL_VERSIONS_FILE"
