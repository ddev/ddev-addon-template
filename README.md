[![tests](https://github.com/ddev/ddev-addon-template/actions/workflows/tests.yml/badge.svg)](https://github.com/ddev/ddev-addon-template/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2025.svg)

# DDEV add-on template <!-- omit in toc -->

* [What is DDEV add-on template?](#what-is-ddev-add-on-template)
* [Components of the repository](#components-of-the-repository)
* [Getting started](#getting-started)
* [How to debug in Github Actions](./README_DEBUG.md)

## What is DDEV add-on template?

This repository is a template for providing [DDEV](https://ddev.readthedocs.io) add-ons and services.

In DDEV, add-ons can be installed from the command line using the `ddev add-on get` command, for example, `ddev add-on get ddev/ddev-redis` or `ddev add-on get ddev/ddev-solr`.

This repository is a quick way to get started. You can create a new repo from this one by clicking the template button in the top right corner of the page.

![template button](images/template-button.png)

## Components of the repository

* The fundamental contents of the add-on service or other component. For example, in this template there is a [docker-compose.addon-template.yaml](docker-compose.addon-template.yaml) file.
* An [install.yaml](install.yaml) file that describes how to install the service or other component.
* A test suite in [test.bats](tests/test.bats) that makes sure the service continues to work as expected.
* [Github actions setup](.github/workflows/tests.yml) so that the tests run automatically when you push to the repository.

## Getting started

1. Choose a good descriptive name for your add-on. It should probably start with "ddev-" and include the basic service or functionality. If it's particular to a specific CMS, perhaps `ddev-<CMS>-servicename`.
2. Create the new template repository by using the template button.
3. Globally replace "addon-template" with the name of your add-on.
4. Add the files that need to be added to a DDEV project to the repository. For example, you might replace `docker-compose.addon-template.yaml` with the `docker-compose.*.yaml` for your recipe.
5. Update the `install.yaml` to give the necessary instructions for installing the add-on:

   * The fundamental line is the `project_files` directive, a list of files to be copied from this repo into the project `.ddev` directory.
   * You can optionally add files to the `global_files` directive as well, which will cause files to be placed in the global `.ddev` directory, `~/.ddev`.
   * Finally, `pre_install_commands` and `post_install_commands` are supported. These can use the host-side environment variables documented [in DDEV docs](https://ddev.readthedocs.io/en/stable/users/extend/custom-commands/#environment-variables-provided).

6. Update `tests/test.bats` to provide a reasonable test for your repository. Tests will run automatically on every push to the repository, and periodically each night. Please make sure to address test failures when they happen. Others will be depending on you. Bats is a testing framework that just uses Bash. To run a Bats test locally, you have to [install bats-core](https://bats-core.readthedocs.io/en/stable/installation.html) first. Then you download your add-on, and finally run `bats ./tests/test.bats` within the root of the uncompressed directory. To learn more about Bats see the [documentation](https://bats-core.readthedocs.io/en/stable/).
7. When everything is working, including the tests, you can push the repository to GitHub.
8. Create a [release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) on GitHub.
9. Test manually with `ddev add-on get <owner/repo>`.
10. You can test PRs with `ddev add-on get https://github.com/<user>/<repo>/tarball/<branch>`
11. Update the `README.md` header, adding the machine name of the add-on, for example `# ddev-redis`, not `# DDEV Redis`.
12. Update the `README.md` to describe the add-on, how to use it, and how to contribute. If there are any manual actions that have to be taken, please explain them. If it requires special configuration of the using project, please explain how to do those. Examples in [ddev/ddev-solr](https://github.com/ddev/ddev-solr), [ddev/ddev-memcached](https://github.com/ddev/ddev-memcached), and (advanced) [ddev-platformsh](https://github.com/ddev/ddev-platformsh).
13. Add a good short description to your repo, and add the [topic](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics) "ddev-get". It will immediately be added to the list provided by `ddev add-on list --all`.
14. When it has matured you will hopefully want to have it become an "official" maintained add-on. Open an issue in the [DDEV queue](https://github.com/ddev/ddev/issues) for that.

Add-ons were covered in [DDEV Add-ons: Creating, maintaining, testing](https://www.youtube.com/watch?v=TmXqQe48iqE) (part of the [DDEV Contributor Live Training](https://ddev.com/blog/contributor-training)).

Note that more advanced techniques are discussed in [Advanced Add-On Techniques](https://ddev.com/blog/advanced-add-on-contributor-training/) and [DDEV docs](https://ddev.readthedocs.io/en/stable/users/extend/additional-services/).

**Contributed and maintained by `@CONTRIBUTOR`**
