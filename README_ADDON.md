[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/ddev/ddev-addon-template/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ddev/ddev-addon-template/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/ddev/ddev-addon-template)](https://github.com/ddev/ddev-addon-template/commits)
[![release](https://img.shields.io/github/v/release/ddev/ddev-addon-template)](https://github.com/ddev/ddev-addon-template/releases/latest)

# DDEV Add-on Template

## Overview

This add-on integrates Add-on Template into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get ddev/ddev-addon-template
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Add-on Template |
| `ddev logs -s addon-template` | Check Add-on Template logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.addon-template --addon-template-docker-image="busybox:stable"
ddev add-on get ddev/ddev-addon-template
ddev restart
```

Make sure to commit the `.ddev/.env.addon-template` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `ADDON_TEMPLATE_DOCKER_IMAGE` | `--addon-template-docker-image` | `busybox:stable` |

## Credits

**Contributed and maintained by @CONTRIBUTOR**
