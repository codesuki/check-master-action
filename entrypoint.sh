#!/bin/bash

main () {
    set -e

    BASE=$1
    BRANCH=$2 #$(git rev-parse --abbrev-ref HEAD)
    PATH_REGEX=$3

    PR_CHANGED_PATHS=$(git diff --name-only "$(git merge-base "$BASE" "$BRANCH")" "$BRANCH" | grep -o -P "$PATH_REGEX" | uniq | sort)

    MASTER_CHANGED_PATHS=$(git diff --name-only "$(git merge-base "$BASE" "$BRANCH")" "$BASE" | grep -o -P "$PATH_REGEX" | uniq | sort)

    BOTH_CHANGED_PATHS=$(comm -12 <(echo "$PR_CHANGED_PATHS") <(echo "$MASTER_CHANGED_PATHS"))

    if [ -z "$BOTH_CHANGED_PATHS" ]
    then
        # OK TO MERGE
        exit 0
    else
        echo "$BOTH_CHANGED_PATHS"
        exit 1
    fi
}

main "$@"
