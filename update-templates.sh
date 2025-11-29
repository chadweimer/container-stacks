#!/usr/bin/env bash
set -euo pipefail

# update-templates.sh - generate templates.json from template folders
# Uses template.json for metadata and example.env for env variable definitions
# Requires: jq

ROOT="$(pwd)"
TEMPLATES_DIR="${TEMPLATES_DIR:-${ROOT}}"
OUT_FILE="${OUT_FILE:-templates.json}"
REGISTRY_VERSION="${REGISTRY_VERSION:-3}"
REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/chadweimer/container-stacks}"

command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed" >&2; exit 1; }

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/-+/-/g; s/^-|-$//g'
}

tmp_entries=$(mktemp)
trap 'rm -f "$tmp_entries"' EXIT

compose_candidates=(compose.yaml docker-compose.yml docker-compose.yaml compose.yml)
count=0
id_counter=0

for d in "$TEMPLATES_DIR"/*/; do
  [ -d "$d" ] || continue
  dir_name=$(basename "$d")
  id=$(slugify "$dir_name")
  tdir="$d"

  meta_path="$tdir/template.json"
  if [ ! -f "$meta_path" ]; then
    echo "Missing ${meta_path#${ROOT}/}. Skipping" >&2
    continue
  fi

  # find compose file
  compose_file=""
  for c in "${compose_candidates[@]}"; do
    if [ -f "$tdir/$c" ]; then
      compose_file="$c"
      break
    fi
  done
  if [ -z "$compose_file" ]; then
    echo "No compose file found in ${tdir#${ROOT}/} (looked for ${compose_candidates[*]})" >&2
    continue
  fi

  # find env example
  env_example=""
  if [ -f "$tdir/example.env" ]; then
    env_example="$tdir/example.env"
  elif [ -f "$tdir/.env.example" ]; then
    env_example="$tdr/.env.example"
  fi
  if [ -z "$env_example" ] || [ ! -f "$env_example" ]; then
    echo "Missing example.env or .env.example in ${tdir#${ROOT}/}. Skipping" >&2
    continue
  fi

  # read metadata
  name=$(jq -r '.name // empty' "$meta_path")
  description=$(jq -r '.description // empty' "$meta_path")
  version=$(jq -r '.version // empty' "$meta_path")
  tags_json=$(jq -c '.tags // []' "$meta_path")

  if [ -z "$name" ] || [ -z "$description" ] || [ -z "$version" ]; then
    echo "templates/${dir_name}/template.json missing/invalid required fields" >&2
    continue
  fi

  # parse env example into a temp file with JSON objects per line
  env_tmp=$(mktemp)
  while IFS= read -r line || [ -n "$line" ]; do
    # strip leading/trailing whitespace
    line_trim=$(printf '%s' "$line" | sed -E 's/^\s+|\s+$//g')
    [ -z "$line_trim" ] && continue
    case "$line_trim" in
      \#*) continue ;;
    esac
    # split on first '='
    name_k=$(printf '%s' "$line_trim" | sed -E 's/=.*$//')
    value_v=$(printf '%s' "$line_trim" | sed -E 's/^[^=]*=//')
    # escape double quotes in value
    value_v_esc=$(printf '%s' "$value_v" | sed -E 's/"/\\\"/g')
    if [ -z "$value_v" ]; then
      printf '{"name":"%s","label":"%s"}\n' "$name_k" "$name_k" >> "$env_tmp"
    else
      printf '{"name":"%s","label":"%s","default":"%s"}\n' "$name_k" "$name_k" "$value_v_esc" >> "$env_tmp"
    fi
  done < "$env_example"

  env_json=$(jq -s '.' "$env_tmp")
  rm -f "$env_tmp"

  stackfile="${dir_name}/${compose_file}"

  # increment numeric id
  id_counter=$((id_counter+1))

  # Build template object matching templates.json structure
  entry=$(jq -n --argjson id "$id_counter" --arg title "$name" \
    --arg description "$description" \
    --arg platform "linux" \
    --arg repository_url "${REPOSITORY_URL}" \
    --arg stackfile "$stackfile" \
    --argjson env "$env_json" \
    --argjson categories "$tags_json" \
    '{"id": $id, "type": 3, "title": $title, "description": $description, "categories": $categories, "platform": $platform, "repository": {"url": $repository_url, "stackfile": $stackfile}, "env": $env}')

  printf '%s
' "$entry" >> "$tmp_entries"
  count=$((count+1))

done

if [ "$count" -eq 0 ]; then
  echo "No templates written" >&2
  exit 1
fi

templates_json=$(jq -s '.' "$tmp_entries")

# Build final templates.json
jq -n --arg version "$REGISTRY_VERSION" --argjson templates "$templates_json" '{version: $version, templates: $templates}' | jq '.' > "$OUT_FILE"

echo "Generated ${OUT_FILE} with ${count} templates"

exit 0
