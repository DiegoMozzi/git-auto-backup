#!/bin/bash

# ==========================================
# Git Auto-Commit & Push Script
# (Sanitized version for publishing)
# Requires GNU coreutils (GNU/Linux).
# ==========================================

# Variables (can be overridden by environment variables)
BASE_DIR="${BASE_DIR:-"$HOME/Projects"}"
LOG="${LOG:-"$HOME/Scripts/git-auto.log"}"
EMAIL="${EMAIL:-""}"  # Configure if you want notifications (not used in this script)
START_TIME=$(date +%s)

# List of allowed repositories (folder names)
ALLOWED_REPOS=(${ALLOWED_REPOS:-"repo1 repo2"})

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG"
    if [ -t 1 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
    fi
}

# Rotate logs (keep for 7 days)
rotate_log() {
    if [ -f "$LOG" ]; then
        local LOG_AGE=$(( ($(date +%s) - $(stat -c %Y "$LOG" 2>/dev/null || echo 0)) / 86400 ))
        if [ $LOG_AGE -gt 7 ]; then
            local OLD_DATE=$(date -r "$LOG" '+%Y%m%d' 2>/dev/null || date '+%Y%m%d')
            mv "$LOG" "${LOG%.*}_${OLD_DATE}.log"
            log_message "Previous log archived as ${LOG%.*}_${OLD_DATE}.log"
        fi
    fi
}

# Check if a repo is allowed
is_repo_allowed() {
    local REPO_NAME="$1"
    for repo in "${ALLOWED_REPOS[@]}"; do
        if [ "$REPO_NAME" = "$repo" ]; then
            return 0
        fi
    done
    return 1
}

process_repo() {
    local REPO_PATH="$1"
    local REPO_NAME
    REPO_NAME=$(basename "$REPO_PATH")

    # Check if repo is in the allowed list
    if ! is_repo_allowed "$REPO_NAME"; then
        log_message "SKIP: $REPO_NAME is not in the allowed list"
        return 0
    fi

    # Change to repo directory
    cd "$REPO_PATH" || return 1

    log_message "=== Processing: $REPO_NAME ==="

    # Check for changes
    if git diff --quiet && git diff --cached --quiet; then
        # Also check for untracked files
        if [ -z "$(git ls-files --others --exclude-standard)" ]; then
            log_message "✓ $REPO_NAME: No changes"
            return 0
        fi
    fi

    # Stage all changes
    git add . 2>/dev/null

    # Check again if there are staged changes
    if git diff --cached --quiet; then
        log_message "✓ $REPO_NAME: No changes to commit"
        return 0
    fi

    # Auto commit message
    local TIMESTAMP
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    local COMMIT_MSG="Auto-backup: $TIMESTAMP"

    # Commit
    if git commit -m "$COMMIT_MSG" >/dev/null 2>&1; then
        log_message "✓ $REPO_NAME: Commit created"

        # Check if remote is configured
        if git remote get-url origin >/dev/null 2>&1; then
            # Try to push
            if git push origin HEAD >/dev/null 2>&1; then
                log_message "✓ $REPO_NAME: Push successful"
                return 0
            else
                log_message "⚠ $REPO_NAME: Commit OK, but push failed"
                return 1
            fi
        else
            log_message "ℹ $REPO_NAME: Commit OK, no remote configured"
            return 0
        fi
    else
        log_message "✗ $REPO_NAME: Commit failed"
        return 1
    fi
}

# === START OF SCRIPT ===

log_message "=========================================="
log_message "STARTING GIT PROCESS - $(date '+%Y-%m-%d %H:%M:%S')"
log_message "=========================================="

# Rotate log if needed
rotate_log

# Check that base directory exists
if [ ! -d "$BASE_DIR" ]; then
    log_message "ERROR: Directory $BASE_DIR does not exist"
    exit 1
fi

# Counters
REPOS_PROCESSED=0
REPOS_CHANGED=0
ERRORS=0

# Find and process repositories
for DIR in "$BASE_DIR"/*; do
    if [ -d "$DIR" ]; then
        REPOS_PROCESSED=$((REPOS_PROCESSED + 1))

        if process_repo "$DIR"; then
            # Check if there were actual changes
            if [ -d "$DIR/.git" ] && ! (git -C "$DIR" diff --quiet && git -C "$DIR" diff --cached --quiet && [ -z "$(git -C "$DIR" ls-files --others --exclude-standard)" ]); then
                REPOS_CHANGED=$((REPOS_CHANGED + 1))
            fi
        else
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# If no directories found, search nested repos
if [ $REPOS_PROCESSED -eq 0 ]; then
    log_message "Searching for nested repositories..."
    find "$BASE_DIR" -name ".git" -type d | while read -r GIT_DIR; do
        REPO_PATH=$(dirname "$GIT_DIR")
        REPOS_PROCESSED=$((REPOS_PROCESSED + 1))

        if process_repo "$REPO_PATH"; then
            REPOS_CHANGED=$((REPOS_CHANGED + 1))
        else
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

# Finish
TOTAL_TIME=$(($(date +%s) - START_TIME))
log_message "=========================================="
log_message "GIT PROCESS COMPLETED"
log_message "Repositories processed: $REPOS_PROCESSED"
log_message "Repositories with changes: $REPOS_CHANGED"
log_message "Total time: ${TOTAL_TIME}s"
log_message "Errors: $ERRORS"
log_message "=========================================="

if [ $ERRORS -eq 0 ]; then
    exit 0
else
    exit 1
fi
