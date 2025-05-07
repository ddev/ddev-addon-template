#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

GITHUB_REPOSITORY=${1?Error: Please pass repo org/name, e.g. ddev/ddev-addon-name}

# Extract variables
FULL_REPO_NAME="$GITHUB_REPOSITORY"
REPO_NAME="${GITHUB_REPOSITORY##*/}"
USER_NAME="${GITHUB_REPOSITORY%%/*}"
REPLACE_UNDERSCORES=${REPO_NAME//_/-}
NO_PREFIX_NAME="${REPLACE_UNDERSCORES#ddev-}"
LOWERCASE_NAME="${NO_PREFIX_NAME,,}"
ENV_VAR_NAME=$(echo "${LOWERCASE_NAME//-/_}_DOCKER_IMAGE" | tr '[:lower:]' '[:upper:]')
PRETTY_NAME=$(echo "$LOWERCASE_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

update_readme() {
    mv README_ADDON.md README.md

    sed -i "s|ddev/ddev-addon-template|$FULL_REPO_NAME|g" README.md
    sed -i "s|addon-template|$LOWERCASE_NAME|g" README.md
    sed -i "s|Add-on Template|$PRETTY_NAME|g" README.md
    sed -i "s|ADDON_TEMPLATE_DOCKER_IMAGE|$ENV_VAR_NAME|g" README.md
    sed -i "s|@CONTRIBUTOR|\[@$USER_NAME\](https://github.com/$USER_NAME)|g" README.md
}

update_docker_compose() {
    local old_file="docker-compose.addon-template.yaml"
    local new_file="docker-compose.$LOWERCASE_NAME.yaml"
    mv "$old_file" "$new_file"

    sed -i "s|addon-template|$LOWERCASE_NAME|g" "$new_file"
    sed -i "s|ADDON_TEMPLATE_DOCKER_IMAGE|$ENV_VAR_NAME|g" "$new_file"
}

update_tests_and_templates() {
    sed -i "s|ddev/ddev-addon-template|$FULL_REPO_NAME|g" tests/test.bats
    sed -i "s|ddev/ddev-addon-template|$FULL_REPO_NAME|g" .github/PULL_REQUEST_TEMPLATE.md
}

update_license() {
    sed -i "s|Copyright \[yyyy\]|Copyright $(date +'%Y')|g" LICENSE
}

create_install_yaml() {
    cat <<EOF > install.yaml
name: $LOWERCASE_NAME

project_files:
  - docker-compose.$LOWERCASE_NAME.yaml

ddev_version_constraint: '>= v1.24.3'
EOF
}

cleanup_files() {
    rm -f README_DEBUG.md
    rm -f .github/workflows/first-time-setup.yml
    rm -rf images
    rm -rf .github/scripts
}

main() {
    update_readme
    update_docker_compose
    update_tests_and_templates
    update_license
    create_install_yaml
    cleanup_files
}

main
