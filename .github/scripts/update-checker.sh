#!/usr/bin/env bash

set -o errexit
set -o nounset

UPSTREAM=https://github.com/ddev/ddev-addon-template/blob/main

# List to store info messages
info_messages=()

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

    # Minimum required DDEV version v1.24.10
    local min_ddev_major=1
    local min_ddev_minor=24
    local min_ddev_patch=10

    if [[ -f "$install_yaml" ]]; then
        # Check for ddev_version_constraint >= minimum required version
        local has_valid_version=false
        if grep -q "^ddev_version_constraint:" "$install_yaml"; then
            # Extract the version number from the constraint (handles both single and double quotes)
            local version_string
            version_string=$(grep "^ddev_version_constraint:" "$install_yaml" | head -1 | sed "s/^ddev_version_constraint: ['\"]>= v//; s/['\"].*//" | grep -o "^[0-9.]*")

            if [[ -n "$version_string" ]]; then
                # Split version into components
                local major minor patch
                IFS='.' read -r major minor patch <<< "$version_string"
                major=${major:-0}
                minor=${minor:-0}
                patch=${patch:-0}

                # Check if version is >= minimum required version
                if (( major > min_ddev_major )) || \
                   (( major == min_ddev_major && minor > min_ddev_minor )) || \
                   (( major == min_ddev_major && minor == min_ddev_minor && patch >= min_ddev_patch )); then
                    has_valid_version=true
                fi
            fi
        fi

        if [[ "$has_valid_version" != "true" ]]; then
            actions+=("install.yaml should contain \`ddev_version_constraint: '>= v${min_ddev_major}.${min_ddev_minor}.${min_ddev_patch}'\` or higher, see upstream file $UPSTREAM/$install_yaml")
        fi

        # Check for addon-template
        if grep -q "addon-template" "$install_yaml"; then
            actions+=("install.yaml should not contain 'addon-template', use your own name")
        fi

        # Check for #ddev-nodisplay tag
        if grep -q "#ddev-nodisplay" "$install_yaml"; then
            actions+=("install.yaml should not contain '#ddev-nodisplay' tag, it's not used anymore, see upstream file $UPSTREAM/$install_yaml")
        fi
    else
        actions+=("install.yaml is missing, see upstream file $UPSTREAM/$install_yaml")
    fi
}

# Check tests/*.bats for required conditions
check_test_bats() {
    local test_bats="tests/test.bats"
    local bats_files

    # Find any .bats files in tests directory
    mapfile -t bats_files < <(find tests -maxdepth 1 -name "*.bats" -type f 2>/dev/null)

    if [[ ${#bats_files[@]} -eq 0 ]]; then
        actions+=("tests/ directory should contain at least one .bats test file, see upstream file $UPSTREAM/tests/test.bats")
        return
    fi

    # If tests/test.bats exists, check it for required content
    if [[ -f "$test_bats" ]]; then
        # Check for test_tags=release
        if grep -q "install from release" "$test_bats" && ! grep -q "# bats test_tags=release" "$test_bats"; then
            actions+=("$test_bats should contain '# bats test_tags=release', see upstream file $UPSTREAM/tests/test.bats")
        fi

        # Check for ddev add-on get
        if ! grep -q "ddev add-on get" "$test_bats"; then
            actions+=("$test_bats should contain 'ddev add-on get', see upstream file $UPSTREAM/tests/test.bats")
        fi

        # Check for GITHUB_ENV usage
        if ! grep -q "GITHUB_ENV" "$test_bats"; then
            actions+=("$test_bats should use GITHUB_ENV in teardown() function, see upstream file $UPSTREAM/tests/test.bats")
        fi

        # Check for DDEV_NONINTERACTIVE=true
        if ! grep -q "DDEV_NONINTERACTIVE=true" "$test_bats"; then
            actions+=("$test_bats should set DDEV_NONINTERACTIVE=true, see upstream file $UPSTREAM/tests/test.bats")
        fi

        # Check for DDEV_NO_INSTRUMENTATION=true
        if ! grep -q "DDEV_NO_INSTRUMENTATION=true" "$test_bats"; then
            actions+=("$test_bats should set DDEV_NO_INSTRUMENTATION=true, see upstream file $UPSTREAM/tests/test.bats")
        fi

        # Check for GITHUB_REPO
        if ! grep -q "GITHUB_REPO" "$test_bats"; then
            actions+=("$test_bats should define GITHUB_REPO, see upstream file $UPSTREAM/tests/test.bats")
        fi

        # Check for bats_load_library
        if ! grep -q "bats_load_library" "$test_bats"; then
            actions+=("$test_bats should use bats_load_library, see upstream file $UPSTREAM/tests/test.bats")
        fi
    else
        # Warn if using non-standard test files
        info_messages+=("$test_bats not found, skipping detailed checks. Found test files: ${bats_files[*]}")
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
        # Check for at least 2 instances of paths-ignore
        local paths_ignore_count
        paths_ignore_count=$(grep -o "paths-ignore:" "$tests_yml" 2>/dev/null | wc -l)
        if (( paths_ignore_count < 2 )); then
            actions+=("$tests_yml should contain at least 2 instances of 'paths-ignore:', found $paths_ignore_count, see upstream file $UPSTREAM/$tests_yml")
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
                actions+=("$file contains 'build:', but there is no 'image:', example: 'image: \${ADDON_TEMPLATE_DOCKER_IMAGE:-ddev/ddev-utilities:latest}-\${DDEV_SITENAME}-built', this is required to use DDEV offline")
            elif grep -q "build:" "$file" && grep -q "image:" "$file" && ! grep -Eq "image:.*-\\\$\{DDEV_SITENAME\}-built" "$file"; then
                actions+=("$file contains both 'build:' and 'image:', but 'image:' line should contain '-\${DDEV_SITENAME}-built', example: 'image: \${ADDON_TEMPLATE_DOCKER_IMAGE:-ddev/ddev-utilities:latest}-\${DDEV_SITENAME}-built', this is required to use DDEV offline")
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
        if ! grep -q "REPLACE_ME_WITH_THIS_PR_NUMBER" "$pr_template"; then
            actions+=("PULL_REQUEST_TEMPLATE.md should contain 'ddev add-on get https://github.com/<your-name>/<your-repo>/tarball/refs/pull/REPLACE_ME_WITH_THIS_PR_NUMBER/head', see upstream file $UPSTREAM/$pr_template?plain=1")
        fi
    fi
}

# Check all files for "addon-template" mentions
check_addon_template_mentions() {
    local file
    for file in install.yaml README.md docker-compose.*.yaml tests/test.bats .github/PULL_REQUEST_TEMPLATE.md; do
        if [[ -f "$file" ]]; then
            if grep -q "ddev/ddev-addon-template" "$file"; then
                actions+=("Replace 'ddev/ddev-addon-template' mentions with your add-on name in: $file")
            elif grep -q "addon-template" "$file"; then
                actions+=("Replace 'addon-template' mentions with your add-on name in: $file")
            fi
            if grep -q "ADDON_TEMPLATE" "$file"; then
                actions+=("Replace 'ADDON_TEMPLATE' mentions with your add-on name in: $file")
            fi
            if grep -q "Add-on Template" "$file"; then
                actions+=("Replace 'Add-on Template' mentions with your add-on name in: $file")
            fi
        fi
    done
}

# Check LICENSE file for Apache License
check_license() {
    local license_file="LICENSE"
    
    if [[ -f "$license_file" ]]; then
        if ! grep -q "Apache License" "$license_file"; then
            actions+=("LICENSE should contain 'Apache License', see upstream file $UPSTREAM/$license_file")
        fi
    else
        actions+=("LICENSE is missing, see upstream file $UPSTREAM/$license_file")
    fi
}

# Check .gitattributes
check_gitattributes() {
  local gitattributes=".gitattributes"

  if [[ -f "$gitattributes" ]]; then
    if ! grep -q "tests" "$gitattributes"; then
      actions+=("$gitattributes should contain 'tests', see upstream file $UPSTREAM/$gitattributes")
    fi
  else
    actions+=("$gitattributes is missing, see upstream file $UPSTREAM/$gitattributes")
  fi
}

# Check for trailing newline and whitespace-only lines in all files
check_file_formatting() {
    local file

    # Check if git command exists
    if ! command -v git >/dev/null 2>&1; then
        info_messages+=("git command not found, skipping file formatting checks")
        return
    fi

    # Check for untracked files
    if [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
        actions+=("Untracked files exist. Please stage or remove them before running file formatting checks.")
        return
    fi

    # Get all tracked files from git, excluding binary files and specific patterns
    while IFS= read -r -d '' file; do
        # Skip binary files and images
        if file "$file" 2>/dev/null | grep -qE "image|binary|executable|archive"; then
            continue
        fi

        # Check if file ends with a newline
        if [[ -n "$(tail -c 1 "$file" 2>/dev/null)" ]]; then
            actions+=("$file should have an empty line at the end")
        fi

        # Check for lines containing only whitespace
        if grep -qn '^[[:space:]]\+$' "$file" 2>/dev/null; then
            actions+=("$file contains lines with only spaces/tabs, remove trailing whitespace")
        fi
    done < <(git ls-files -z 2>/dev/null | grep -zv '^tests/testdata/')
}

# Main function
main() {
    if [[ ! -f "install.yaml" ]]; then
        echo "ERROR: run this script from the add-on root directory, install.yaml is missing" >&2
        exit 1
    fi

    # Check unnecessary files
    check_remove_file "docker-compose.addon-template.yaml"
    check_remove_file "README_ADDON.md"
    check_remove_file "README_DEBUG.md"
    check_remove_file "images/gh-tmate.jpg"
    check_remove_file "images/template-button.png"
    check_remove_file ".github/scripts/first-time-setup.sh"
    check_remove_file ".github/scripts/update-checker.sh"
    check_remove_file ".github/workflows/first-time-setup.yml"

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

    # Check for addon-template mentions
    check_addon_template_mentions

    # Check LICENSE file
    check_license

    # Check .gitattributes
    check_gitattributes

    # Check file formatting
    check_file_formatting

    # Display info messages if any
    if [[ ${#info_messages[@]} -gt 0 ]]; then
        echo "INFO:" >&2
        local info
        for info in "${info_messages[@]}"; do
            echo "- $info" >&2
        done
    fi

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
