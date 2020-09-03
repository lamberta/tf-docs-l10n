# Helper utilities for GitHub Actions jobs.
# To include: source ./tools/ci/utils.sh

# Print files modified in this pull request (and not deleted).
# Usage: readarray -t changed_files < <(get_changed_files)
get_changed_files() {
  local branch="${1:-master}"

  while read fp; do
    if [[ -e "$fp" ]]; then
      echo "$fp"
    fi
  done < <(git diff --name-only "$branch" || true)
}

# Add label(s) to GitHub issue.
# Requires environment variables `ISSUE_URL` and `GITHUB_TOKEN`.
add_label() {
  local label
  # Deduplicate args.
  declare -A labels_set
  for label in "$@"; do
    labels_set["$label"]=1
  done

  # Collect labels and join with comma.
  local i=1 len="${#labels_set[@]}" item items
  for label in "${!labels_set[@]}"; do
    item=$(printf '"%s"' "$label")
    items="${items}${item}"

    if (( i < len )); then items="${items}, "; fi
    ((i+=1))
  done
  # Create the JSON payload.
  local json_str=$(printf '{"labels": [%s]}' "$items")

  if [[ -z "ISSUE_URL" ]]; then
    echo "add_label: Requires env variable: ISSUE_URL"
    exit 1
  fi
  if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "add_label: Requires env variable: GITHUB_TOKEN"
    exit 1
  fi

  curl -X POST \
       -H "Accept: application/vnd.github.v3+json" \
       -H "Authorization: token ${GITHUB_TOKEN}" \
       "${ISSUE_URL}/labels" \
       --data "$json_str"
}
