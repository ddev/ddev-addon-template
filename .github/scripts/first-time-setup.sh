#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

GITHUB_REPOSITORY=${1?Error: Please pass repo org/name, e.g. ddev/ddev-addon-name}

FULL_REPO_NAME="$GITHUB_REPOSITORY"
REPO_NAME="${GITHUB_REPOSITORY##*/}"
USER_NAME="${GITHUB_REPOSITORY%%/*}"
REPLACE_UNDERSCORES=${REPO_NAME//_/-}
NO_PREFIX_NAME="${REPLACE_UNDERSCORES#ddev-}"
LOWERCASE_NAME="${NO_PREFIX_NAME,,}"
ENV_VARIABLE_NAME_DOCKER_IMAGE=$(echo "${LOWERCASE_NAME//-/_}_DOCKER_IMAGE" | tr '[:lower:]' '[:upper:]')
PRETTY_NAME=$(echo "${LOWERCASE_NAME}" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

echo "[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/$FULL_REPO_NAME/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/$FULL_REPO_NAME/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/$FULL_REPO_NAME)](https://github.com/$FULL_REPO_NAME/commits)
[![release](https://img.shields.io/github/v/release/$FULL_REPO_NAME)](https://github.com/$FULL_REPO_NAME/releases/latest)

# DDEV $PRETTY_NAME

## Overview

This add-on integrates $PRETTY_NAME into your [DDEV](https://ddev.com/) project.

## Installation

\`\`\`bash
ddev add-on get $FULL_REPO_NAME
ddev restart
\`\`\`

After installation, make sure to commit the \`.ddev\` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| \`ddev describe\` | View service status and used ports for $PRETTY_NAME |
| \`ddev logs -s $LOWERCASE_NAME\` | Check $PRETTY_NAME logs |

## Advanced Customization

To change the Docker image:

\`\`\`bash

ddev dotenv set .ddev/.env.$LOWERCASE_NAME --$LOWERCASE_NAME-docker-image="busybox:stable"
ddev add-on get $FULL_REPO_NAME
ddev restart
\`\`\`

Make sure to commit the \`.ddev/.env.$LOWERCASE_NAME\` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| \`$ENV_VARIABLE_NAME_DOCKER_IMAGE\` | \`--$LOWERCASE_NAME-docker-image\` | \`busybox:stable\` |

## Credits

**Contributed and maintained by [@$USER_NAME](https://github.com/$USER_NAME)**" > README.md

mv docker-compose.addon-template.yaml "docker-compose.$LOWERCASE_NAME.yaml"
sed -i "s|addon-template|$LOWERCASE_NAME|g" "docker-compose.$LOWERCASE_NAME.yaml"
sed -i "s|ADDON_TEMPLATE_DOCKER_IMAGE|$ENV_VARIABLE_NAME_DOCKER_IMAGE|g" "docker-compose.$LOWERCASE_NAME.yaml"

sed -i "s|ddev/ddev-addon-template|$FULL_REPO_NAME|g" tests/test.bats
sed -i "s|ddev/ddev-addon-template|$FULL_REPO_NAME|g" .github/PULL_REQUEST_TEMPLATE.md

echo "name: $LOWERCASE_NAME

project_files:
  - docker-compose.$LOWERCASE_NAME.yaml

ddev_version_constraint: '>= v1.24.3'" > install.yaml

rm -f README_DEBUG.md
rm -f .github/workflows/first-time-setup.yml
rm -rf images
rm -rf .github/scripts
