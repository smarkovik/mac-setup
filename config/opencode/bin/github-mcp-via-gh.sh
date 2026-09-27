#!/usr/bin/env bash
# Start GitHub MCP using the token from `gh auth` (keyring). No Docker.
# Used by OpenCode Desktop via mcp.github.command — GUI apps do not inherit shell exports.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "github-mcp-via-gh: gh not on PATH" >&2
  exit 1
fi
if ! command -v npx >/dev/null 2>&1; then
  echo "github-mcp-via-gh: npx not on PATH" >&2
  exit 1
fi

TOKEN="$(gh auth token 2>/dev/null)" || {
  echo "github-mcp-via-gh: gh auth token failed — run: gh auth login" >&2
  exit 1
}
if [ -z "$TOKEN" ]; then
  echo "github-mcp-via-gh: empty token from gh" >&2
  exit 1
fi

export GITHUB_PERSONAL_ACCESS_TOKEN="$TOKEN"
export GITHUB_TOKEN="$TOKEN"
exec npx -y @modelcontextprotocol/server-github
