#!/bin/bash

# Git Branch Helper - Shows all directories with same remote origin and their current branches
# Usage: ./git-branch-helper.sh <directory_name>

# Check if directory name is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory_name>"
    echo "Example: $0 my-project"
    exit 1
fi

TARGET_DIR="$1"

# Check if the target directory exists in current working directory
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found in current directory"
    exit 1
fi

# Check if target directory is a git repository
if [ ! -d "$TARGET_DIR/.git" ]; then
    echo "Error: '$TARGET_DIR' is not a git repository"
    exit 1
fi

# Get the remote origin URL from the target directory
cd "$TARGET_DIR"
ORIGIN_URL=$(git remote get-url origin 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$ORIGIN_URL" ]; then
    echo "Error: No remote origin found for '$TARGET_DIR'"
    exit 1
fi

# Return to original directory
cd ..

echo "Remote origin: $ORIGIN_URL"
echo "Directories with matching origin:"
echo

# Look through all directories in current working directory
for dir in */; do
    # Remove trailing slash
    dir=${dir%/}

    # Skip if not a directory or not a git repository
    if [ ! -d "$dir/.git" ]; then
        continue
    fi

    # Get remote origin for this directory
    cd "$dir"
    CURRENT_ORIGIN=$(git remote get-url origin 2>/dev/null)

    # If origins match, get all local branches
    if [ "$CURRENT_ORIGIN" = "$ORIGIN_URL" ]; then
        CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
        if [ -z "$CURRENT_BRANCH" ]; then
            CURRENT_BRANCH="(detached HEAD)"
        fi

        # Get all local branches, remove leading spaces and asterisk
        LOCAL_BRANCHES=$(git branch 2>/dev/null | sed 's/^[ *]*//')

        # Show current branch first, then others
        echo "$dir - $CURRENT_BRANCH (current)"

        # Show other local branches
        while IFS= read -r branch; do
            if [ "$branch" != "$CURRENT_BRANCH" ] && [ -n "$branch" ]; then
                echo "$dir - $branch"
            fi
        done <<<"$LOCAL_BRANCHES"

        echo # Add blank line between directories for readability
    fi

    # Return to parent directory
    cd ..
done