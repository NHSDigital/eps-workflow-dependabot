#!/bin/bash
set -euo pipefail

# Script to update asdf version in .tool-versions.asdf file
# Usage: update-asdf-version.sh <new-version> [asdf-version-file]

NEW_VERSION="$1"
ASDF_VERSION_FILE="${2:-.tool-versions.asdf}"

if [[ ! -f "$ASDF_VERSION_FILE" ]]; then
  echo "Error: $ASDF_VERSION_FILE not found"
  exit 1
fi

# Create a backup
cp "$ASDF_VERSION_FILE" "${ASDF_VERSION_FILE}.bak"

# Read the file and update the version line (non-comment, non-empty line)
awk -v version="$NEW_VERSION" '
  /^#/ { print; next }
  /^[[:space:]]*$/ { print; next }
  !updated { print version; updated=1; next }
  {print}
' "${ASDF_VERSION_FILE}.bak" > "$ASDF_VERSION_FILE"

# Remove backup
rm "${ASDF_VERSION_FILE}.bak"

echo "Updated asdf to $NEW_VERSION in $ASDF_VERSION_FILE"
