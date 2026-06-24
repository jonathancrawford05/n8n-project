#!/usr/bin/env bash
#
# Back up all n8n workflows to this git repo as version-controlled JSON.
#
# Why this exists: n8n's built-in "Push to Git" (Source Control) is a paid
# Business/Enterprise feature. This script gives the same outcome on the free
# community edition by using the n8n CLI to export workflows, then committing
# them to git.
#
# Usage:
#   ./scripts/backup-workflows.sh           # export + commit locally
#   PUSH=1 ./scripts/backup-workflows.sh    # export + commit + git push
#
# Override the container name if yours differs:
#   N8N_CONTAINER=my-n8n ./scripts/backup-workflows.sh
#
set -euo pipefail

CONTAINER="${N8N_CONTAINER:-n8n}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_DIR="$REPO_DIR/workflows"
# Export into the n8n home dir, which the container's "node" user owns and can
# write to. (Avoid /tmp — docker-compose bind-mounts the host's /tmp/n8n-temp
# over it, which the non-root user often can't write to.)
CONTAINER_TMP="/home/node/.n8n/.workflow-backup"

# 1. Sanity checks ----------------------------------------------------------
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found on PATH." >&2; exit 1; }
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "ERROR: container '$CONTAINER' is not running." >&2
  echo "       Start n8n (docker compose up -d) or set N8N_CONTAINER." >&2
  exit 1
fi

mkdir -p "$WORKFLOW_DIR"

# 2. Export workflows inside the container ----------------------------------
# --backup = --all --pretty --separate: one pretty-printed JSON per workflow,
# named by workflow ID. Pretty-printing keeps git diffs readable.
echo "Exporting workflows from container '$CONTAINER'..."
docker exec "$CONTAINER" rm -rf "$CONTAINER_TMP"
docker exec "$CONTAINER" mkdir -p "$CONTAINER_TMP"
docker exec "$CONTAINER" n8n export:workflow --backup --output="$CONTAINER_TMP/"

# 3. Copy them into the repo ------------------------------------------------
# Clear stale files first so deleted/renamed workflows are reflected in git.
rm -f "$WORKFLOW_DIR"/*.json 2>/dev/null || true
docker cp "$CONTAINER:$CONTAINER_TMP/." "$WORKFLOW_DIR/"
echo "Exported $(ls -1 "$WORKFLOW_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ') workflow file(s) to workflows/"

# 4. Commit (and optionally push) -------------------------------------------
cd "$REPO_DIR"
if [[ -z "$(git status --porcelain -- "$WORKFLOW_DIR")" ]]; then
  echo "No workflow changes to commit."
  exit 0
fi

git add "$WORKFLOW_DIR"
git commit -m "n8n workflow backup: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Committed workflow changes."

if [[ "${PUSH:-0}" == "1" ]]; then
  git push
  echo "Pushed to remote."
else
  echo "Run 'git push' (or PUSH=1 next time) to publish."
fi
