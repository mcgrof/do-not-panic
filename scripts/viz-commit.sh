#!/bin/bash
# Auto-commit pending changes using Claude Code.
# Called by `make viz` after the pipeline finishes.

set -e

SOB_NAME=$(git config user.name)
SOB_EMAIL=$(git config user.email)

# Bail if nothing to commit
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "[COMMIT] Nothing to commit"
    exit 0
fi

echo "[COMMIT] Generating commit message with Claude..."

# Gather context for Claude
STATUS=$(git status --short)
DIFF=$(git diff --stat)
UNTRACKED=$(git ls-files --others --exclude-standard)

# Stage everything
git add -A

STAGED_DIFF=$(git diff --cached)

# Ask Claude to write the commit message
MSG=$(cat <<PROMPT | claude -p
You are writing a git commit message for the do-not-panic.com visualizations repo.

Here are the staged changes:

git status --short:
$STATUS

git diff --cached:
$STAGED_DIFF

Write a commit message following these rules:
- Subject line: short, imperative, under 72 chars
- Body: plain english, explain what and why, no shopping cart lists
- End with exactly these two lines (no blank line between them):

Generated-by: Claude AI
Signed-off-by: $SOB_NAME <$SOB_EMAIL>

Output ONLY the commit message, nothing else.
PROMPT
)

if [ -z "$MSG" ]; then
    echo "[COMMIT] ERROR: Claude returned empty message" >&2
    exit 1
fi

echo ""
echo "--- Commit message ---"
echo "$MSG"
echo "----------------------"
echo ""

git commit -m "$MSG"
echo "[COMMIT] Done"
