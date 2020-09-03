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
  # Collect args and join with comma.
  local i=1 len="$#" item items
  for ((; i<=$len; i+=1 )); do
    item=$(printf '"%s"' "${!i}")
    items="${items}${item}"
    if (( i < len )); then items="${items}, "; fi
  done

  if [[ -z "ISSUE_URL" ]]; then
    echo "add_label: Requires env variable: ISSUE_URL"
    exit 1
  fi
  if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "add_label: Requires env variable: GITHUB_TOKEN"
    exit 1
  fi
  local json_str=$(printf '{"labels": [%s]}' "$items")
  curl -X POST \
       -H "Accept: application/vnd.github.v3+json" \
       -H "Authorization: token ${GITHUB_TOKEN}" \
       "${ISSUE_URL}/labels" \
       --data "$json_str"
}
