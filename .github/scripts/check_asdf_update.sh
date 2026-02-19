#!/bin/bash
set -euo pipefail

# Script to check for updates to asdf version in .tool-versions.asdf
# Outputs JSON object with update info to stdout

ASDF_VERSION_FILE="${1:-.tool-versions.asdf}"

if [[ ! -f "$ASDF_VERSION_FILE" ]]; then
  echo "Error: $ASDF_VERSION_FILE not found" >&2
  exit 1
fi

# Read current version from file (skip comments and empty lines)
current_version=$(grep -v '^#' "$ASDF_VERSION_FILE" | grep -v '^[[:space:]]*$' | head -n1 | xargs)

if [[ -z "$current_version" ]]; then
  echo "Error: Could not find version in $ASDF_VERSION_FILE" >&2
  exit 1
fi

echo "Checking asdf (current: $current_version)..." >&2

# Get latest version from GitHub releases
latest_version=$(curl -s https://api.github.com/repos/asdf-vm/asdf/releases/latest | jq -r '.tag_name' | sed 's/^v//')

if [[ -z "$latest_version" ]]; then
  echo "Warning: Could not fetch latest asdf version" >&2
  echo "{}"
  exit 0
fi

echo "  Latest version: $latest_version" >&2

# Compare versions
if [[ "$current_version" != "$latest_version" ]]; then
  # Parse version numbers
  IFS='.' read -ra current_parts <<< "$current_version"
  IFS='.' read -ra latest_parts <<< "$latest_version"
  
  current_major="${current_parts[0]}"
  current_minor="${current_parts[1]:-0}"
  
  latest_major="${latest_parts[0]}"
  latest_minor="${latest_parts[1]:-0}"
  
  # Determine update type
  update_type="patch"
  if [[ "$latest_major" != "$current_major" ]]; then
    update_type="major"
  elif [[ "$latest_minor" != "$current_minor" ]]; then
    update_type="minor"
  fi
  
  echo "  Update available: $update_type" >&2
  
  # Output JSON
  jq -n \
    --arg current "$current_version" \
    --arg latest "$latest_version" \
    --arg type "$update_type" \
    '{current_version: $current, latest_version: $latest, update_type: $type}'
else
  echo "  Already up to date" >&2
  echo "{}"
fi
