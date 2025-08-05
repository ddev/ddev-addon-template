#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

UPSTREAM=https://github.com/ddev/ddev-addon-template/blob/main

# List to store actions
actions=()

# Check for unnecessary files and suggest removal
check_remove_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        actions+=("Remove unnecessary file: $file")
    fi
}

# Check README.md for required conditions
check_readme() {
    local readme="README.md"
    local badge

    if [[ -f "$readme" ]]; then
        # Check for 'ddev add-on get'
        if ! grep -q "ddev add-on get" "$readme"; then
            actions+=("README.md should contain 'ddev add-on get', see upstream file $UPSTREAM/README_ADDON.md?plain=1")
        fi

        # Check for 'ddev get'
        if grep -q "ddev get" "$readme"; then
            actions+=("Remove 'ddev get' from README.md, see upstream file $UPSTREAM/README_ADDON.md?plain=1")
        fi

        # Check for required badges and replacements
        if grep -q "project is maintained" "$readme"; then
            actions+=("README.md should not contain 'project is maintained' badge, see upstream file $UPSTREAM/README_ADDON.md?plain=1")
        fi

        # Ensure the required badges are present
        for badge in "add-on registry" "tests" "last commit" "release"; do
            if ! grep -q "$badge" "$readme"; then
                actions+=("README.md should contain badge: $badge, see upstream file $UPSTREAM/README_ADDON.md?plain=1")
            fi
        done
    else
        actions+=("README.md is missing, see upstream file $UPSTREAM/README_ADDON.md?plain=1")
    fi
}

# Check install.yaml for required conditions
check_install_yaml() {
    local install_yaml="install.yaml"

    if [[ -f "$install_yaml" ]]; then
        # Check for ddev_version_constraint
        if ! grep -q "^ddev_version_constraint: '>= v1\.24\.[3-9][0-9]*'" "$install_yaml" && ! grep -q "^ddev_version_constraint: '>= v1\.2[5-9]\." "$install_yaml"; then
            actions+=("install.yaml should contain 'ddev_version_constraint: \">= v1.24.3\"' or higher, see upstream file $UPSTREAM/$install_yaml")
        fi

        # Check for addon-template
        if grep -q "addon-template" "$install_yaml"; then
            actions+=("install.yaml should not contain 'addon-template', use your own name")
        fi
    else
        actions+=("install.yaml is missing, see upstream file $UPSTREAM/$install_yaml")
    fi
}

# Check tests/test.bats for required conditions
check_test_bats() {
    local test_bats="tests/test.bats"

    if [[ -f "$test_bats" ]]; then
        # Check for test_tags=release
        if grep -q "install from release" "$test_bats" && ! grep -q "# bats test_tags=release" "$test_bats"; then
            actions+=("$test_bats should contain '# bats test_tags=release', see upstream file $UPSTREAM/$test_bats")
        fi

        # Check for ddev add-on get
        if ! grep -q "ddev add-on get" "$test_bats"; then
            actions+=("$test_bats should contain 'ddev add-on get', see upstream file $UPSTREAM/$test_bats")
        fi
    else
        actions+=("$test_bats is missing, see upstream file $UPSTREAM/$test_bats")
    fi
}

# Check for correct shebang in commands/**/* files
check_shebang() {
    local file
    while IFS= read -r -d '' file; do
        if [[ -f "$file" && -r "$file" ]]; then
            local first_line
            first_line=$(head -n1 "$file" 2>/dev/null || echo "")
            if [[ "$first_line" == "#!/bin/bash" ]]; then
                actions+=("$file should use '#!/usr/bin/env bash' instead of '#!/bin/bash'")
            fi
        fi
    done < <(find commands -type f -print0 2>/dev/null || true)
}

# Check .github/workflows/tests.yml for required conditions
check_tests_workflow() {
    local tests_yml=".github/workflows/tests.yml"

    if [[ -f "$tests_yml" ]]; then
        # Check for ddev/github-action-add-on-test@v2
        if ! grep -q "ddev/github-action-add-on-test@v2" "$tests_yml"; then
            actions+=("$tests_yml should use 'ddev/github-action-add-on-test@v2', see upstream file $UPSTREAM/$tests_yml")
        fi
        # Check for paths-ignore
        if ! grep -q "paths-ignore" "$tests_yml"; then
            actions+=("$tests_yml should have 'paths-ignore' for markdown, see upstream file $UPSTREAM/$tests_yml")
        fi
    else
        actions+=("$tests_yml is missing, see upstream file $UPSTREAM/$tests_yml")
    fi
}

# Check docker-compose.*.yaml files for 'build:' with 'image:' usage
check_docker_compose_yaml() {
    local file
    while IFS= read -r -d '' file; do
        if [[ -f "$file" && -r "$file" ]]; then
            if grep -q "build:" "$file" && ! grep -q "image:" "$file"; then
                actions+=("$file contains 'build:', but there is no 'image:', example: 'image: \${ADDON_TEMPLATE_DOCKER_IMAGE:-busybox:stable}-\${DDEV_SITENAME}-built', this is required to use DDEV offline")
            elif grep -q "build:" "$file" && grep -q "image:" "$file" && ! grep -Eq "image:.*-\\\$\{DDEV_SITENAME\}-built" "$file"; then
                actions+=("$file contains both 'build:' and 'image:', but 'image:' line should contain '-\${DDEV_SITENAME}-built', example: 'image: \${ADDON_TEMPLATE_DOCKER_IMAGE:-busybox:stable}-\${DDEV_SITENAME}-built', this is required to use DDEV offline")
            fi
        fi
    done < <(find . -name "docker-compose.*.yaml" -print0 2>/dev/null || true)
}

# Check for required GitHub template files
check_github_templates() {
    local templates=(
        ".github/ISSUE_TEMPLATE/bug_report.yml"
        ".github/ISSUE_TEMPLATE/feature_request.yml"
        ".github/PULL_REQUEST_TEMPLATE.md"
    )
    local template

    for template in "${templates[@]}"; do
        if [[ ! -f "$template" ]]; then
            actions+=("GitHub template missing: $template, see upstream file $UPSTREAM/$template?plain=1")
        fi
    done

    # Check PULL_REQUEST_TEMPLATE.md for the forbidden exact link
    local pr_template=".github/PULL_REQUEST_TEMPLATE.md"
    if [[ -f "$pr_template" ]]; then
        if grep -q "https://github.com/<user>/<repo>/tarball/<branch>" "$pr_template"; then
            actions+=("PULL_REQUEST_TEMPLATE.md should not contain 'https://github.com/<user>/<repo>/tarball/<branch>', see upstream file $UPSTREAM/$pr_template?plain=1")
        fi
    fi
}

# Main function
main() {
    if [[ ! -f "install.yaml" ]]; then
        echo "ERROR: run this script from the add-on root directory, install.yaml is missing" >&2
        exit 1
    fi

    # Check unnecessary files
    check_remove_file "README_ADDON.md"
    check_remove_file "README_DEBUG.md"
    check_remove_file "images/gh-tmate.jpg"
    check_remove_file "images/template--button.png"
    check_remove_file "docker-compose.addon-template.yaml"

    # Check README.md for conditions
    check_readme

    # Check install.yaml for conditions
    check_install_yaml

    # Check docker-compose.*.yaml for conditions
    check_docker_compose_yaml

    # Check tests/test.bats for conditions
    check_test_bats

    # Check shebang in commands/**/* files
    check_shebang

    # Check tests workflow
    check_tests_workflow

    # Check GitHub templates
    check_github_templates

    # If any actions are needed, throw an error
    if [[ ${#actions[@]} -gt 0 ]]; then
        echo "ERROR: Actions needed:" >&2
        local action
        for action in "${actions[@]}"; do
            echo "- $action" >&2
        done
        exit 1
    else
        echo "All checks passed, no actions needed."
    fi
}

# Run the main function
main
