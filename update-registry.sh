#!/usr/bin/env bash
set -euo pipefail

# reg.sh - generate registry.json from templates directory (bash equivalent of reg.ts)
# Requires: jq

ROOT="$(pwd)"
TEMPLATES_DIR="${TEMPLATES_DIR:-${ROOT}}"

REGISTRY_NAME="${REGISTRY_NAME:-My Container Stacks}"
REGISTRY_DESCRIPTION="${REGISTRY_DESCRIPTION:-Collection of compose templates maintained by me.}"
REGISTRY_AUTHOR="${REGISTRY_AUTHOR:-chadweimer}"
REGISTRY_URL="${REGISTRY_URL:-https://github.com/chadweimer/container-stacks}"
PUBLIC_BASE="${PUBLIC_BASE:-https://raw.githubusercontent.com/chadweimer/container-stacks/main}"
DOCS_BASE="${DOCS_BASE:-${REGISTRY_URL}/tree/main}"
SCHEMA_URL="${SCHEMA_URL:-https://registry.getarcane.app/schema.json}"
BUMP_PART="${BUMP_PART:-minor}"

REG_OUT="${REG_OUT:-registry.json}"

command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed" >&2; exit 1; }

slugify() {
  local s="$1"
  # lowercase, replace non a-z0-9 with '-', collapse, trim
  printf '%s' "$s" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/-+/-/g; s/^-|-$//g'
}

bump_semver() {
  local v="$1" part="$2"
  if ! [[ $v =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    echo "1.0.0"
    return
  fi
  IFS=. read -r major minor patch <<< "$v"
  case "$part" in
    major)
      major=$((major+1)); minor=0; patch=0
      ;;
    patch)
      patch=$((patch+1))
      ;;
    *)
      minor=$((minor+1)); patch=0
      ;;
  esac
  echo "${major}.${minor}.${patch}"
}

prev_version=""
declare -A prev_ids
if [ -f "$REG_OUT" ]; then
  prev_version=$(jq -r '.version // empty' "$REG_OUT" || echo "")
  # read previous ids into associative array for quick lookup
  while IFS= read -r id; do
    prev_ids["$id"]=1
  done < <(jq -r '.templates[].id' "$REG_OUT" 2>/dev/null || true)
fi

tmp_entries=$(mktemp)
trap 'rm -f "$tmp_entries"' EXIT

if [ ! -d "$TEMPLATES_DIR" ]; then
  echo "Templates directory '$TEMPLATES_DIR' not found" >&2
  exit 1
fi

compose_candidates=(compose.yaml docker-compose.yml docker-compose.yaml compose.yml)
count=0
new_ids_list=()

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
    exit 1
  fi

  env_example="$tdir/example.env"
  if [ ! -f "$env_example" ]; then
    echo "Missing ${env_example#${ROOT}/}" >&2
    exit 1
  fi

  name=$(jq -r '.name // empty' "$meta_path")
  description=$(jq -r '.description // empty' "$meta_path")
  version=$(jq -r '.version // empty' "$meta_path")
  tags_json=$(jq -c '.tags // []' "$meta_path")

  if [ -z "$name" ] || [ -z "$description" ] || [ -z "$version" ]; then
    echo "templates/${dir_name}/template.json missing/invalid required fields" >&2
    exit 1
  fi
  # ensure tags is a non-empty array
  tags_count=$(jq -r 'length' <(printf '%s' "$tags_json") 2>/dev/null || echo 0)
  if [ "$tags_count" -eq 0 ]; then
    echo "templates/${dir_name}/template.json must include non-empty \"tags\"" >&2
    exit 1
  fi

  compose_url="${PUBLIC_BASE}/${id}/${compose_file}"
  env_url="${PUBLIC_BASE}/${id}/example.env"
  documentation_url="${DOCS_BASE}/${id}/README.md"

  # build JSON object for this template
  entry=$(jq -n --arg id "$id" \
    --arg name "$name" \
    --arg description "$description" \
    --arg version "$version" \
    --arg author "${REGISTRY_AUTHOR}" \
    --arg compose_url "$compose_url" \
    --arg env_url "$env_url" \
    --arg documentation_url "$documentation_url" \
    --argjson tags "$tags_json" \
    '{id:$id, name:$name, description:$description, version:$version, author:$author, compose_url:$compose_url, env_url:$env_url, documentation_url:$documentation_url, tags:$tags}')

  printf '%s\n' "$entry" >> "$tmp_entries"
  count=$((count+1))

  if [ -z "${prev_ids[$id]:-}" ]; then
    new_ids_list+=("$id")
  fi
done

if [ "$count" -eq 0 ]; then
  echo "No templates found in $TEMPLATES_DIR" >&2
  exit 1
fi

templates_json=$(jq -s 'sort_by(.id)' "$tmp_entries")

base_version="${prev_version:-${REGISTRY_VERSION:-1.0.0}}"
if [ "${#new_ids_list[@]}" -gt 0 ]; then
  next_version=$(bump_semver "$base_version" "$BUMP_PART")
  echo "Detected ${#new_ids_list[@]} new template(s): ${new_ids_list[*]} -> bumping ${BUMP_PART} to ${next_version}"
else
  next_version="$base_version"
  echo "No new templates detected -> keeping version ${base_version}"
fi

# Build final registry JSON
jq -n --arg schema "$SCHEMA_URL" \
  --arg name "${REGISTRY_NAME}" \
  --arg description "${REGISTRY_DESCRIPTION}" \
  --arg author "${REGISTRY_AUTHOR}" \
  --arg url "${REGISTRY_URL}" \
  --arg version "$next_version" \
  --argjson templates "$templates_json" \
  '{"$schema": $schema, name: $name, description: $description, author: $author, url: $url, version: $version, templates: $templates}' \
  | jq '.' > "$REG_OUT"

echo "Generated ${REG_OUT} with ${count} templates"

exit 0
