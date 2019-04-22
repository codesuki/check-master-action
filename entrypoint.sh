#!/bin/bash

base_commit() {
    local _BASE
    _BASE=$1

    local _BRANCH
    _BRANCH=$2

    git merge-base "$_BASE" "$_BRANCH"
}

changed_paths() {
    local _BASE_COMMIT
    _BASE_COMMIT=$1

    local _BRANCH
    _BRANCH=$2

    git diff --name-only "$_BASE_COMMIT" "$_BRANCH"
}

filter_paths() {
    local _PATH_REGEX
    _PATH_REGEX=$1

    grep -o -P "$_PATH_REGEX" | uniq | sort
}

main() {
    set -e

    BASE=$1; shift
    BRANCH=$1; shift
    PATH_REGEXES=$@

    BASE_COMMIT=$(base_commit "$BASE" "$BRANCH")

    PR_CHANGED_PATHS=$(changed_paths "$BASE_COMMIT" "$BRANCH")
    PR_MATCHED_PATHS=""
    for regex in $PATH_REGEXES; do
        PR_MATCHED_PATHS+=$(echo "$PR_CHANGED_PATHS" | filter_paths "$regex")$'\n'
    done

    MASTER_CHANGED_PATHS=$(changed_paths "$BASE_COMMIT" "$BASE")
    MASTER_MATCHED_PATHS=""
    for regex in $PATH_REGEXES; do
        MASTER_MATCHED_PATHS+=$(echo "$MASTER_CHANGED_PATHS" | filter_paths "$regex")$'\n'
    done

    BOTH_CHANGED_PATHS=$(comm -12 <(echo "$PR_MATCHED_PATHS") <(echo "$MASTER_MATCHED_PATHS"))
    if [ -z "$BOTH_CHANGED_PATHS" ]
    then
        # OK TO MERGE
        exit 0
    else
        echo "$BOTH_CHANGED_PATHS"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
