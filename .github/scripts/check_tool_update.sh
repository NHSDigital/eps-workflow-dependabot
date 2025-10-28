#!/bin/bash
set -euo pipefail

# Script to check for updates to tools in .tool-versions file
# Outputs JSON array of updates to stdout

TOOL_VERSIONS_FILE="${1:-.tool-versions}"

if [[ ! -f "$TOOL_VERSIONS_FILE" ]]; then
  echo "Error: $TOOL_VERSIONS_FILE not found" >&2
  exit 1
fi

# Initialize output array
updates='[]'

# Read each line from .tool-versions
while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip empty lines and comments
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  
  # Parse tool and current version
  tool=$(echo "$line" | awk '{print $1}')
  current_version=$(echo "$line" | awk '{print $2}')
  
  echo "Checking $tool (current: $current_version)..." >&2
  
  # Get latest version based on tool type
  latest_version=""
  
  case "$tool" in
    nodejs)
      # Get latest LTS version from nodejs.org
      latest_version=$(curl -s https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)] | .[0].version' | sed 's/^v//')
      ;;
    python)
      # Get latest stable version from python.org
      latest_version=$(curl -s https://www.python.org/api/v2/downloads/release/?is_published=true | jq -r '[.[] | select(.is_latest == true and (.name | startswith("Python 3")))] | .[0].name' | sed 's/Python //')
      ;;
    poetry)
      # Get latest version from GitHub releases
      latest_version=$(curl -s https://api.github.com/repos/python-poetry/poetry/releases/latest | jq -r '.tag_name' | sed 's/^v//')
      ;;
    actionlint)
      # Get latest version from GitHub releases
      latest_version=$(curl -s https://api.github.com/repos/rhysd/actionlint/releases/latest | jq -r '.tag_name' | sed 's/^v//')
      ;;
    shellcheck)
      # Get latest version from GitHub releases
      latest_version=$(curl -s https://api.github.com/repos/koalaman/shellcheck/releases/latest | jq -r '.tag_name' | sed 's/^v//')
      ;;
    maven)
      # Get latest version from Maven releases
      latest_version=$(curl -s https://api.github.com/repos/apache/maven/releases/latest | jq -r '.tag_name' | sed 's/^maven-//')
      ;;
    java)
      # Handle corretto versions - extract version from current
      if [[ "$current_version" =~ ^corretto- ]]; then
        base_version="${current_version#corretto-}"
        # Get major version (e.g., 21 from 21.xxx)
        major_version=$(echo "$base_version" | cut -d. -f1)
        # Get latest corretto version for this major version from GitHub
        latest_version=$(curl -s "https://api.github.com/repos/corretto/corretto-${major_version}/releases/latest" | jq -r '.tag_name' | sed 's/^/corretto-/')
        # If API fails, try alternative approach with tags
        if [[ -z "$latest_version" || "$latest_version" == "corretto-null" ]]; then
          latest_version=$(curl -s "https://api.github.com/repos/corretto/corretto-${major_version}/tags" | jq -r '.[0].name' | sed 's/^/corretto-/')
        fi
      else
        # For non-corretto java, get latest OpenJDK version
        latest_version=$(curl -s https://api.github.com/repos/adoptium/temurin-build/releases/latest | jq -r '.tag_name' | sed 's/^jdk-//' | sed 's/+/-/')
      fi
      ;;
    direnv)
      # Get latest version from GitHub releases
      latest_version=$(curl -s https://api.github.com/repos/direnv/direnv/releases/latest | jq -r '.tag_name' | sed 's/^v//')
      ;;
    *)
      echo "Warning: Unknown tool '$tool', skipping" >&2
      continue
      ;;
  esac
  
  if [[ -z "$latest_version" ]]; then
    echo "Warning: Could not fetch latest version for $tool" >&2
    continue
  fi
  
  echo "  Latest version: $latest_version" >&2
  
  # Compare versions
  if [[ "$current_version" != "$latest_version" ]]; then
    # Handle special version formats (e.g., corretto-21.xxx)
    current_cmp="$current_version"
    latest_cmp="$latest_version"
    
    # Strip prefixes for comparison
    if [[ "$tool" == "java" ]]; then
      current_cmp="${current_version#corretto-}"
      latest_cmp="${latest_version#corretto-}"
    fi
    
    # Parse version numbers
    IFS='.' read -ra current_parts <<< "$current_cmp"
    IFS='.' read -ra latest_parts <<< "$latest_cmp"
    
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
    
    # Add to updates array
    update_json=$(jq -n \
      --arg tool "$tool" \
      --arg current "$current_version" \
      --arg latest "$latest_version" \
      --arg type "$update_type" \
      '{tool: $tool, current_version: $current, latest_version: $latest, update_type: $type}')
    
    updates=$(echo "$updates" | jq --argjson item "$update_json" '. += [$item]')
  else
    echo "  Already up to date" >&2
  fi
  
done < "$TOOL_VERSIONS_FILE"

# Output final JSON
echo "$updates"
