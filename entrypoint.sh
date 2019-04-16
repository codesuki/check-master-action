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

    local _CHANGED_PATHS
    _CHANGED_PATHS="$(git diff --name-only "$_BASE_COMMIT" "$_BRANCH")"
    echo "$_CHANGED_PATHS"

}

filter_paths() {
    local _PATH_REGEX
    _PATH_REGEX=$1

    local _FILTERED_PATHS
    _FILTERED_PATHS="$(ggrep -o -P "$_PATH_REGEX" | uniq | sort)"
    echo "$_FILTERED_PATHS"
}

main() {
    set -e

    BASE=$1
    BRANCH=$2 #$(git rev-parse --abbrev-ref HEAD)
    PATH_REGEX=$3

    BASE_COMMIT=$(base_commit "$BASE" "$BRANCH")

    PR_CHANGED_PATHS=$(changed_paths "$BASE_COMMIT" "$BRANCH" | filter_paths "$PATH_REGEX")

    MASTER_CHANGED_PATHS=$(changed_paths "$BASE_COMMIT" "$BASE" | filter_paths "$PATH_REGEX")

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  main "$@"
fi
