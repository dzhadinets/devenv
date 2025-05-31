# Docker.io Build Environment

This is the a fork of my work. I did it under the public license in one company.

Docker-based build system is designed to provide a stable environment for every developer to build a variety of CMake, Yocto and AOSP based projects while eliminating the need for thorough manual configuration of build environment

The same robust Docker images and stable building environment have to be reused on production build and integration test servers by all the developers without having to worry about breaking the delicate project build due to package updates on a local system
The devs will catch the issues with build environment first

## Table of Contents

- [Prerequisites](#prerequisites)
- [Directory structure](#directory-structure)
- [Build and install](#install)
- [Builder's scripts](#building-scripts)
  - [Common launching options](#common-launching-options)
  - [`devenv-cmake` usage examples](#cmake-usage-examples)
  - [`devenv-aosp` usage examples](#aosp-usage-examples)
  - [`devenv-yocto` usage examples](#yocto-usage-examples)
- [Project file concept](#project-file)
  - [Project file history](#project-file-history)
- [Environment variables](#environment-variables)
- [Continues integration](#ci)
  - [Yocto](#ci-yocto)
- [Known Issues](#known-issues)

## Prerequisites <a name="prerequisites"></a>

This guide has been tested on
 - [Debian 12](https://www.debian.org/releases/bookworm/)
 - [Ubuntu 18.04 LTS](https://releases.ubuntu.com/18.04/)
 - [Ubuntu 20.04 LTS](https://releases.ubuntu.com/20.04/)
 - [Ubuntu 22.04 LTS](https://releases.ubuntu.com/22.04/)
 - [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install)

Adjust your OS accordingly if you are using another OS distribution

Install packages
`sudo apt install bash make docker.io gawk bmap-tools`

Add your user to docker group
`sudo adduser $USER docker`

Relogin into the system to get your group membership re-evaluated

If you need more details about docker configuration check out [Post-installation steps for Linux](https://docs.docker.com/engine/install/linux-postinstall/)

## Directory structure <a name="directory-structure"></a>

```
├─aosp      # AOSP stuff
├─bin       # building and deployment scripts
│ ├─devenv-aosp    # Android building script
│ ├─devenv-cmake   # CMAKE building script
│ ├─devenv-release # script to generate changelog from git log
│ └─devenv-yocto   # Yocto projects building script
├─ci        # Continuous integration scripts
├─cmake     # CMake stuff
├─docker    # docker files
├─examples  # root folder for examples
│ ├─aosp      # Android examples
│ ├─cmake     # CMAKE examples
│ └─yocto     # Yocto examples
├─ide       # IDE integration support files
│ └─.vscode         # Visual Studio Code integration files
└─scripts   # service scripts used by building system
└─yocto     # YOCTO stuff: graph dependency generator
```

Check out dedicated README files in subdirectories (TBD):
- [examples](examples/README.md)
- [IDE integration](ide/README.md)

## Build and install <a name="install"></a>

Switch to your projects directory root, i.e. `~/Projects`
The environment is installed in-place where you put it and can not be changed after installation (check out `make install` below)

Clone this repository and go there

To show all the available options
`make help`

To build all the docker images
`make docker`

Bash command line completion is supported to help you build individual images, i.e. to build Yocto docker image
`make docker/yocto`

To pass additional parameters into docker builder use option `P=<addons>`

I.e. to rebuild cmake docker image from scratch use `--no-cache` addon
`make docker/cmake-ubuntu20 P=--no-cache`

Add docker scripts directory to the `PATH` environment variable
`make install`

Relogin into the system to make changes to take effect

Make sure your PATH environment variable contains `/devenv/bin`
`echo $PATH`

From here your development environment is set up and ready to use

## Builder's scripts <a name="building-scripts"></a>

Building scripts are responsible for the following tasks:
- Initialize environment variables with default values
- Passes additional parameters inside the docker
- Run docker container and inside it run sync sources procedure that will download all the needed sources
- Prepare development environment and run build target script which will initiate building process
- Terminating the docker container when everything is done

Before invoking building script make sure it's pointing to appropriate version (usually in your devenv/bin directory) i.e.
`which devenv-yocto` or `which devenv-cmake`

It's important if you are working with different versions of building system and have made several installs from different locations

See [Known Issues](#known-issues) section

### Common launching options <a name="common-launching-options"></a>

```bash
  -h|--help                          	- gets this help
  -s|--silent                        	- Do not write messages
  -X|--gui                           	- Provide GUI support
  -i|--image <DOCKER_IMAGE>          	- Force using docker image name
  -n|--non-interactive               	- stop docker from launching STDIN
  -a|--args ARGS                     	- additional params to docker
  -c|--cpus NUMBER                   	- limit docker CPU core usage
```
Help command (--help) is autodocumented for each script, call it for detailed description
### `devenv-cmake` usage examples: <a name="cmake-usage-examples"></a>
```bash
# TBD
```

### `devenv-aosp` usage examples: <a name="aosp-usage-examples"></a>
```bash
# TBD
```

### `devenv-yocto` usage examples: <a name="yocto-usage-examples"></a>
```bash
# TBD
```

## Project file concept  <a name="project-file"></a>

General idea is to have some project.file which points to the root of sources and will store customizable parameters and functions for any project 
for each kind of devenv. In order to track changes in devenv and some project there is the version on the project file.
The version is a string with a template like `<config_version>.<other_version>`
Devenv will fail if `config_version` of a project is differ from internal one.
Backward compatibility is enough hard to implement and I don't think it is needed at the moment.
But migration from previous version of the config is needed. It could be done manually using a history of configs

### History of project.setup <a name="project-file-history"></a>

 -  Version: 0
```bash
# Example of project.setup file.
# Implementation of each function is mandatory. Assumed, they will be called from <ROOT_WORKDIR> dir inside docker

# This script should only be sourced
if [ "$(basename -- "$0")" == "project.setup" ]; then
  echo "Please do not run $0, source it" >&2
  exit 1
fi
YOCTO_CONF_VERSION="0.x"
# Initializes workdir for the project (ie init repo)
# (optional)
function do_init
{
}

# Returns status of sources in the workdir. it can return (echo) "empty" (means: workdir must be initialized), "ready" (sync is not required)
# (optional)
function do_state
{
}

# Source synchronization
# (optional)
function do_sync
{
}

# Prepares dev environment inside the docker
# (optional)
function do_prepare
{
}

# Prebuild step before the building and after source synchronization and environment preparation
# (optional)
function do_workspace
{
}
# Does the building
# this function is mandatory. In case of other repo-based approach for  init/sync/state/prepare/workspace/clean is used
function do_build
{
}
# Cleans workdir
# (optional)
function do_clean
{
}
```

## Environment variables <a name="environment-variables"></a>

Environment variables used by build system to fine control over [docker run](https://docs.docker.com/engine/reference/commandline/run/)
```bash
DOCKER_EXTRA_ARGS={docker_options}      # specify additional docker parameters
DOCKER_WORKDIR=docker_path              # set root folder inside the docker container
DOCKER_VOLUMES={host_path:docker_path;} # list of additional mount points inside the docker container
DOCKER_ENVS={variable=value;}           # list of environment variables to pass in the docker container
DOCKER_DEVS={device{:option};}          # add a host device(s) to the container (docker --device option)
DOCKER_INTERACTIVE=true|false           # explicitly force enable/disable interactive mode
DOCKER_IMAGE=image_name[:image_tag]     # specify docker image to use, i.e. `android_builder:aosp8` (default image tag latest can be omitted)
```
Export them as necessary in your building pipeline

## Continues integration <a name="ci"></a>

I do not want to add some examples. Because there are a lot of CI systems and honestly I do not wand to support them.
But I need to mention what are the common step need to be done to work with builders

### Yocto <a name="ci-yocto"></a>

```bash
# launch ssh agent in order git ssh auth works
eval $(ssh-agent -s)
# add your user keys
ssh-add
# Repo tool needs tricky self update time to time. This is a workaround
pushd .repo/repo/
git pull
popd
# Synchronize meta sources basing your manifest
devenv-yocto --non-interactive sync
# Synchronize bblayers with the set in the project.file
devenv-yocto --non-interactive sync workspace 
# Build your main task
devenv-yocto --non-interactive
```

## Known Issues <a name="known-issues"></a>

- Sometimes parent container can be changed on docker repositories side which may lead to `404 error` at build time
    To fix this problem rebuild the docker image(s) from scratch
    ```bash
    make docker P=--no-cache
    ```
