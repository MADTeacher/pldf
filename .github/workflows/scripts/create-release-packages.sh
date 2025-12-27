#!/usr/bin/env bash
set -euo pipefail

# create-release-packages.sh (workflow-local)
# Build PLDF template release archives for each supported AI assistant and script type.
# Usage: .github/workflows/scripts/create-release-packages.sh <version>
#   Version argument should include leading 'v'.
#   Optionally set AGENTS and/or SCRIPTS env vars to limit what gets built.
#     AGENTS  : space or comma separated subset of: cursor-agent opencode kilocode roo sourcecraft (default: all)
#     SCRIPTS : space or comma separated subset of: sh ps (default: both)

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version-with-v-prefix>" >&2
  exit 1
fi
NEW_VERSION="$1"
if [[ ! $NEW_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like v0.0.0" >&2
  exit 1
fi

echo "Building release packages for $NEW_VERSION"

# Create and use .genreleases directory for all build artifacts
GENRELEASES_DIR=".genreleases"
mkdir -p "$GENRELEASES_DIR"
rm -rf "$GENRELEASES_DIR"/* || true

rewrite_paths() {
  # Skip lines that already have .pldf/ before the target directory to prevent duplication
  sed -E \
    -e '/\.pldf\/memory\//!s@(^|[[:space:]]|`)(/?)memory/@\1.pldf/memory/@g' \
    -e '/\.pldf\/scripts\//!s@(^|[[:space:]]|`)(/?)scripts/@\1.pldf/scripts/@g' \
    -e '/\.pldf\/templates\//!s@(^|[[:space:]]|`)(/?)templates/@\1.pldf/templates/@g' \
    -e '/\.pldf\/hints\//!s@(^|[[:space:]]|`)(/?)hints/@\1.pldf/hints/@g'
}

generate_commands() {
  local agent=$1 ext=$2 arg_format=$3 output_dir=$4 script_variant=$5
  mkdir -p "$output_dir"
  for template in templates/commands/*.md; do
    [[ -f "$template" ]] || continue
    local name description script_command body
    name=$(basename "$template" .md)
    
    # Normalize line endings
    file_content=$(tr -d '\r' < "$template")
    
    # Extract description and script command from YAML frontmatter
    # Use grep + sed instead of awk with pipe to avoid broken pipe errors
    description=$(grep -m1 '^description:' <<< "$file_content" | sed 's/^description:[[:space:]]*//' || true)
    script_command=$(grep -m1 "^[[:space:]]*${script_variant}:" <<< "$file_content" | sed "s/^[[:space:]]*${script_variant}:[[:space:]]*//" || true)
    
    if [[ -z $script_command ]]; then
      # Empty script command is OK for PLDF (most commands don't use external scripts)
      script_command=""
    fi
    
    # Replace {SCRIPT} placeholder with the script command
    body=$(sed "s|{SCRIPT}|${script_command}|g" <<< "$file_content")
    
    # Remove the scripts: section from frontmatter while preserving YAML structure
    # Use here-string instead of pipe to avoid broken pipe errors
    body=$(awk '
      /^---$/ { print; if (++dash_count == 1) in_frontmatter=1; else in_frontmatter=0; next }
      in_frontmatter && /^scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^[a-zA-Z].*:/ && skip_scripts { skip_scripts=0 }
      in_frontmatter && skip_scripts && /^[[:space:]]/ { next }
      { print }
    ' <<< "$body")
    
    # Apply other substitutions
    body=$(sed "s/{ARGS}/$arg_format/g; s/__AGENT__/$agent/g" <<< "$body" | rewrite_paths)
    
    case $ext in
      md)
        echo "$body" > "$output_dir/$name.$ext" ;;
    esac
  done
}

build_variant() {
  local agent=$1 script=$2
  local base_dir="$GENRELEASES_DIR/pldf-${agent}-package-${script}"
  echo "Building $agent ($script) package..."
  mkdir -p "$base_dir"
  
  # Copy base structure but filter scripts by variant
  PLDF_DIR="$base_dir/.pldf"
  mkdir -p "$PLDF_DIR"
  
  [[ -d memory ]] && { cp -r memory "$PLDF_DIR/"; echo "Copied memory -> .pldf"; }
  [[ -d hints ]] && { cp -r hints "$PLDF_DIR/"; echo "Copied hints -> .pldf"; }
  
  # Only copy the relevant script variant directory
  if [[ -d scripts ]]; then
    mkdir -p "$PLDF_DIR/scripts"
    case $script in
      sh)
        [[ -d scripts/bash ]] && { cp -r scripts/bash "$PLDF_DIR/scripts/"; echo "Copied scripts/bash -> .pldf/scripts"; }
        # Copy any script files that aren't in variant-specific directories
        find scripts -maxdepth 1 -type f -exec cp {} "$PLDF_DIR/scripts/" \; 2>/dev/null || true
        ;;
      ps)
        [[ -d scripts/powershell ]] && { cp -r scripts/powershell "$PLDF_DIR/scripts/"; echo "Copied scripts/powershell -> .pldf/scripts"; }
        # Copy any script files that aren't in variant-specific directories
        find scripts -maxdepth 1 -type f -exec cp {} "$PLDF_DIR/scripts/" \; 2>/dev/null || true
        ;;
    esac
  fi
  
  [[ -d templates ]] && { mkdir -p "$PLDF_DIR/templates"; find templates -type f -not -path "templates/commands/*" -exec cp --parents {} "$PLDF_DIR"/ \; ; echo "Copied templates -> .pldf/templates"; }

  case $agent in
    cursor-agent)
      mkdir -p "$base_dir/.cursor/commands"
      generate_commands cursor-agent md "\$ARGUMENTS" "$base_dir/.cursor/commands" "$script" ;;
    opencode)
      mkdir -p "$base_dir/.opencode/command"
      generate_commands opencode md "\$ARGUMENTS" "$base_dir/.opencode/command" "$script" ;;
    kilocode)
      mkdir -p "$base_dir/.kilocode/rules"
      generate_commands kilocode md "\$ARGUMENTS" "$base_dir/.kilocode/rules" "$script" ;;
    roo)
      mkdir -p "$base_dir/.roo/rules"
      generate_commands roo md "\$ARGUMENTS" "$base_dir/.roo/rules" "$script" ;;
    sourcecraft)
      mkdir -p "$base_dir/.codeassistant/commands"
      generate_commands sourcecraft md "\$ARGUMENTS" "$base_dir/.codeassistant/commands" "$script" ;;
  esac
  ( cd "$base_dir" && zip -r "../pldf-template-${agent}-${script}-${NEW_VERSION}.zip" . )
  echo "Created $GENRELEASES_DIR/pldf-template-${agent}-${script}-${NEW_VERSION}.zip"
}

# Determine agent list
ALL_AGENTS=(cursor-agent opencode kilocode roo sourcecraft)
ALL_SCRIPTS=(sh ps)

norm_list() {
  # convert comma+space separated -> line separated unique while preserving order of first occurrence
  tr ',\n' '  ' | awk '{for(i=1;i<=NF;i++){if(!seen[$i]++){printf((out?"\n":"") $i);out=1}}}END{printf("\n")}'
}

validate_subset() {
  local type=$1; shift; local -n allowed=$1; shift; local items=("$@")
  local invalid=0
  for it in "${items[@]}"; do
    local found=0
    for a in "${allowed[@]}"; do [[ $it == "$a" ]] && { found=1; break; }; done
    if [[ $found -eq 0 ]]; then
      echo "Error: unknown $type '$it' (allowed: ${allowed[*]})" >&2
      invalid=1
    fi
  done
  return $invalid
}

if [[ -n ${AGENTS:-} ]]; then
  mapfile -t AGENT_LIST < <(printf '%s' "$AGENTS" | norm_list)
  validate_subset agent ALL_AGENTS "${AGENT_LIST[@]}" || exit 1
else
  AGENT_LIST=("${ALL_AGENTS[@]}")
fi

if [[ -n ${SCRIPTS:-} ]]; then
  mapfile -t SCRIPT_LIST < <(printf '%s' "$SCRIPTS" | norm_list)
  validate_subset script ALL_SCRIPTS "${SCRIPT_LIST[@]}" || exit 1
else
  SCRIPT_LIST=("${ALL_SCRIPTS[@]}")
fi

echo "Agents: ${AGENT_LIST[*]}"
echo "Scripts: ${SCRIPT_LIST[*]}"

for agent in "${AGENT_LIST[@]}"; do
  for script in "${SCRIPT_LIST[@]}"; do
    build_variant "$agent" "$script"
  done
done

echo "Archives in $GENRELEASES_DIR:"
ls -1 "$GENRELEASES_DIR"/pldf-template-*-"${NEW_VERSION}".zip

