#!/usr/bin/env bash
set -euo pipefail

# update-registry.sh - generate registry.json from templates directory
# Requires: jq

ROOT="$(pwd)"
TEMPLATES_DIR="${TEMPLATES_DIR:-${ROOT}}"

REGISTRY_NAME="${REGISTRY_NAME:-My Container Stacks}"
REGISTRY_DESCRIPTION="${REGISTRY_DESCRIPTION:-Collection of compose templates maintained by me.}"
REGISTRY_AUTHOR="${REGISTRY_AUTHOR:-chadweimer}"
REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/chadweimer/container-stacks}"
PUBLIC_BASE="${PUBLIC_BASE:-https://raw.githubusercontent.com/chadweimer/container-stacks/main}"
DOCS_BASE="${DOCS_BASE:-${REPOSITORY_URL}/tree/main}"
SCHEMA_URL="${SCHEMA_URL:-https://registry.getarcane.app/schema.json}"

REG_OUT="${REG_OUT:-registry.json}"
TEM_OUT="${TEM_OUT:-templates.json}"

command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed" >&2; exit 1; }

slugify() {
  local s="$1"
  # lowercase, replace non a-z0-9 with '-', collapse, trim
  printf '%s' "$s" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/-+/-/g; s/^-|-$//g'
}

bump_semver() {
  local v="$1" part="$2"
  if ! [[ $v =~ ^([1-9]+)\.([0-9]+)\.([0-9]+) ]]; then
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

tmp_reg_entries=$(mktemp)
trap 'rm -f "$tmp_reg_entries"' EXIT

tmp_tem_entries=$(mktemp)
trap 'rm -f "$tmp_tem_entries"' EXIT

if [ ! -d "$TEMPLATES_DIR" ]; then
  echo "Templates directory '$TEMPLATES_DIR' not found" >&2
  exit 1
fi

compose_candidates=(compose.yaml docker-compose.yml docker-compose.yaml compose.yml)
count=0
new_ids_list=()

# gather directories and sort by name
dirs=()
while IFS= read -r -d '' entry; do
  dirs+=("$entry")
done < <(find "$TEMPLATES_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0)

# build sorted basename list
sorted_names=$(for p in "${dirs[@]}"; do basename "$p"; done | sort)

# iterate sorted directories
while IFS= read -r dir_name; do
  [ -n "$dir_name" ] || continue
  d="$TEMPLATES_DIR/$dir_name/"
  [ -d "$d" ] || continue
  id=$(slugify "$dir_name")
  tdir="$d"

  meta_path="$tdir/template.json"
  if [ ! -f "$meta_path" ]; then
    echo "Missing ${meta_path#${ROOT}/}. Skipping" >&2
    continue
  fi

  count=$((count+1))
  if [ -z "${prev_ids[$id]:-}" ]; then
    new_ids_list+=("$id")
  else
    unset "prev_ids[$id]"
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

  # find env example
  env_example=""
  if [ -f "$tdir/example.env" ]; then
    env_example="$tdir/example.env"
  elif [ -f "$tdir/.env.example" ]; then
    env_example="$tdr/.env.example"
  fi
  if [ -z "$env_example" ] || [ ! -f "$env_example" ]; then
    echo "Missing example.env or .env.example in ${tdir#${ROOT}/}." >&2
    exit 1
  fi

  # read metadata
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

  # ---- registry.json entry ----

  compose_url="${PUBLIC_BASE}/${id}/${compose_file}"
  env_url="${PUBLIC_BASE}/${id}/example.env"
  documentation_url="${DOCS_BASE}/${id}/README.md"

  # build JSON object for this template
  reg_entry=$(jq -n --arg id "$id" \
    --arg name "$name" \
    --arg description "$description" \
    --arg version "$version" \
    --arg author "${REGISTRY_AUTHOR}" \
    --arg compose_url "$compose_url" \
    --arg env_url "$env_url" \
    --arg documentation_url "$documentation_url" \
    --argjson tags "$tags_json" \
    '{id:$id, name:$name, description:$description, version:$version, author:$author, compose_url:$compose_url, env_url:$env_url, documentation_url:$documentation_url, tags:$tags}')

  printf '%s\n' "$reg_entry" >> "$tmp_reg_entries"


  # ---- templates.json entry ----

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

  # Build template object matching templates.json structure
  tem_entry=$(jq -n --argjson id "$count" --arg title "$name" \
    --arg description "$description" \
    --arg platform "linux" \
    --arg repository_url "${REPOSITORY_URL}" \
    --arg stackfile "$stackfile" \
    --argjson env "$env_json" \
    --argjson categories "$tags_json" \
    '{"id": $id, "type": 3, "title": $title, "description": $description, "categories": $categories, "platform": $platform, "repository": {"url": $repository_url, "stackfile": $stackfile}, "env": $env}')

  printf '%s\n' "$tem_entry" >> "$tmp_tem_entries"
done <<< "$sorted_names"

if [ "$count" -eq 0 ]; then
  echo "No templates found in $TEMPLATES_DIR" >&2
  exit 1
fi

# ---- registry.json ----

registry_json=$(jq -s 'sort_by(.id)' "$tmp_reg_entries")

base_version="${prev_version:-0.0.0}"
if [ "${#new_ids_list[@]}" -gt 0 ]; then
  next_version=$(bump_semver "$base_version" "minor")
  echo "Detected ${#new_ids_list[@]} new template(s): ${new_ids_list[*]} -> bumping registry.json minor to ${next_version}"
elif [ "${#prev_ids[@]}" -gt 0 ]; then
  next_version=$(bump_semver "$base_version" "major")
  echo "Detected ${#prev_ids[@]} removed template(s): ${!prev_ids[*]} -> bumping registry.json major to ${next_version}"
else
  next_version="$base_version"
  echo "No new or removed templates detected -> keeping registry.json version ${base_version}"
fi

# Build final registry JSON
jq -n --arg schema "$SCHEMA_URL" \
  --arg name "${REGISTRY_NAME}" \
  --arg description "${REGISTRY_DESCRIPTION}" \
  --arg author "${REGISTRY_AUTHOR}" \
  --arg url "${REPOSITORY_URL}" \
  --arg version "$next_version" \
  --argjson templates "$registry_json" \
  '{"$schema": $schema, name: $name, description: $description, author: $author, url: $url, version: $version, templates: $templates}' \
  | jq '.' > "$REG_OUT"


# ---- templates.json ----

templates_json=$(jq -s '.' "$tmp_tem_entries")

# Build final templates.json
jq -n --arg version "3" \
  --argjson templates "$templates_json" \
  '{version: $version, templates: $templates}' \
  | jq '.' > "$TEM_OUT"

echo "Generated ${REG_OUT} and ${TEM_OUT} with ${count} templates"

exit 0
