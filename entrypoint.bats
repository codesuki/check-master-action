#!/usr/bin/env bats


@test "e2e" {
    source 'entrypoint.sh'

    CHANGED_PATHS_MASTER=$(cat <<'EOF'
terraform/microservices/service-a/prd/variables.tf
terraform/microservices/service-b/prd/variables.tf
terraform/microservices/service-b/dev/config.tf
EOF
                        )

    CHANGED_PATHS_PR=$(cat <<'EOF'
terraform/microservices/service-a/prd/config.tf
terraform/microservices/service-b/prd/config.tf
EOF
                    )

    function git() {
        if [[ "$1" == "merge-base" ]]; then
            echo "0xDEADBEEF"
        elif [[ "$1" == "diff" ]]; then
            if [[ "$4" == "pr" ]]; then
                echo "$CHANGED_PATHS_PR"
            elif [[ "$4" == "master" ]]; then
                echo "$CHANGED_PATHS_MASTER"
            fi
        fi
    }

    EXPECTED=$(cat <<'EOF'
terraform/microservices/service-a/prd/
terraform/microservices/service-b/prd/
EOF
            )

    run main master pr "terraform/microservices/service-a/[A-Za-z]+/" "terraform/microservices/service-b/[A-Za-z]+/"

    # run splits output on newlines. bring them back.
    output=$( IFS=$'\n'; echo "${lines[*]}" )
    [ "$status" -eq 1 ]
    [ "$output" = "$EXPECTED" ]
}

@test "matches whole path regex" {
    source 'entrypoint.sh'

    CHANGED_PATHS=$(cat <<'EOF'
terraform/microservices/service-a/prd/config.tf
terraform/microservices/service-b/dev/config.tf
EOF
                     )

    EXPECTED=$(cat <<'EOF'
terraform/microservices/service-a/prd/config.tf
terraform/microservices/service-b/dev/config.tf
EOF
            )

    PATH_REGEX=".*"

    RESULT=$(echo "$CHANGED_PATHS" | filter_paths "$PATH_REGEX")
    [ "$RESULT" = "$EXPECTED" ]
}

@test "matches up until service name" {
    source 'entrypoint.sh'

    CHANGED_PATHS=$(cat <<'EOF'
terraform/microservices/service-a/prd/config.tf
terraform/microservices/service-b/dev/config.tf
EOF
                     )

    EXPECTED=$(cat <<'EOF'
terraform/microservices/service-a/
terraform/microservices/service-b/
EOF
            )

    PATH_REGEX="terraform/microservices/[A-Za-z-]+/"

    RESULT=$(echo "$CHANGED_PATHS" | filter_paths "$PATH_REGEX")
    [ "$RESULT" = "$EXPECTED" ]
}

@test "matches up until environment name" {
    source 'entrypoint.sh'

    CHANGED_PATHS=$(cat <<'EOF'
terraform/microservices/service-a/prd/config.tf
terraform/microservices/service-b/dev/config.tf
EOF
                     )

    EXPECTED=$(cat <<'EOF'
terraform/microservices/service-a/prd/
terraform/microservices/service-b/dev/
EOF
            )

    PATH_REGEX="terraform/microservices/[A-Za-z-]+/[A-Za-z]+/"

    RESULT=$(echo "$CHANGED_PATHS" | filter_paths "$PATH_REGEX")
    [ "$RESULT" = "$EXPECTED" ]
}
