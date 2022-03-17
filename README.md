# GitHub Actions Runner

This project implements a self-hosted GitHub Actions Runner, tuned for use from
within Kubernetes clusters. The project implements an [Ubuntu][ubuntu]-based
Docker image for setting up, running and [registering][register] a runner within
an Organisation or a Repository. This image **requires** [sysbox], an
alternative OCI runtime. [sysbox] makes it possible to run Docker in Docker
(DinD) without having to rely on elevated privileges.

  [ubuntu]: https://hub.docker.com/_/ubuntu
  [register]: https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners
  [sysbox]: https://github.com/nestybox/sysbox

## Features

* Dynamic registration of the runner at GitHub.
* Runner registration for an entire organisation, or for a repository.
* Support for both enterprise installations, and `github.com`.
* Support for [labels] and [groups] to categorise runners.
* Able to run all [types] of actions, including [Docker][container-action]
  container actions!
* Multi-platform [support](#supported-arhitectures).
* Each runner can be customised/configured through running a series of
  script/programs prior to registration at the GitHub server.
* Automatically [follows](#releases) the [release] tempo of the official
  [runner]. Generated images will be tagged with the SemVer of the release.
* `latest` tag will correspond to latest [release] of the [runner] and this
  project.
* Fully automated [workflows](.github/workflows/README.md), manual interaction
  possible.
* Comes bundled with latest `docker compose` (v2, the plugin), together with the
  `docker-compose` [shim] and a few other essential [tools](#available-tools).
* Within containers, workflows are executed by a regular user called `runner`.

  [labels]: https://docs.github.com/en/actions/hosting-your-own-runners/using-labels-with-self-hosted-runners
  [groups]: https://docs.github.com/en/actions/hosting-your-own-runners/managing-access-to-self-hosted-runners-using-groups
  [types]: https://docs.github.com/en/actions/creating-actions/about-custom-actions#types-of-actions
  [container-action]: https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
  [release]: https://github.com/actions/runner/releases
  [runner]: https://github.com/actions/runner
  [shim]: https://github.com/docker/compose-switch

## Environment Variables

This runner recognises the following environment variables for its
configuration.

| Environment Variable | Description |
| --- | --- |
| `RUNNER_NAME` | The name of the runner to use. Supercedes (overrides) `RUNNER_NAME_PREFIX` |
| `RUNNER_NAME_PREFIX` | A prefix for a randomly generated name (followed by a random 13 digit string). You must not also provide `RUNNER_NAME`. Defaults to `github-runner` |
| `ACCESS_TOKEN` | A [github PAT](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) to use to generate `RUNNER_TOKEN` dynamically at container start. Not using this requires a valid `RUNNER_TOKEN` |
| `ORG_RUNNER` | Only valid if using `ACCESS_TOKEN`. This will set the runner to an org runner. Default is 'false'. Valid values are 'true' or 'false'. If this is set to true you must also set `ORG_NAME` and makes `REPO_URL` unneccesary |
| `ORG_NAME` | The organization name for the runner to register under. Requires `ORG_RUNNER` to be 'true'. No default value. |
| `LABELS` | A comma separated string to indicate the labels. Default is 'default' |
| `REPO_URL` | If using a non-organization runner this is the full repository url to register under such as 'https://github.com/Mitigram/gh-runner-sysbox' |
| `RUNNER_TOKEN` | If not using a PAT for `ACCESS_TOKEN` this will be the runner token provided by the Add Runner UI (a manual process). Note: This token is short lived and will change frequently. `ACCESS_TOKEN` is likely preferred. |
| `RUNNER_WORKDIR` | The working directory for the runner. Runners on the same host should not share this directory. Default is '/_work'. This must match the source path for the bind-mounted volume at RUNNER_WORKDIR, in order for container actions to access files. |
| `RUNNER_GROUP` | Name of the runner group to add this runner to (defaults to the default runner group) |
| `GITHUB_HOST` | Optional URL of the Github Enterprise server e.g github.mycompany.com. Defaults to `github.com`. |
| `RUNNER_PREFLIGHT_PATH` | A colon separated list of directories. All executable files present will be run before the rootless daemon is running and runner registered. Defaults to empty. |
| `RUNNER_INIT_PATH` | A colon separated list of directories. All executable files present will be run once the rootless daemon is running, but before the runner is registered. Defaults to empty. |
| `RUNNER_CLEANUP_PATH` | A colon separated list of directories. All executable files present will be run after the runner has been deregistered. Defaults to empty. |

## Available Tools

This images does **not** contain **all** the tools that GitHub offers by default
in their runners. Workflows might work improperly when running from within
runners created using this image. The [Dockerfile](./Dockerfile) for the runner
images ensures:

* An installation of the Docker daemon, including the `docker` cli binary.
* An installation of Docker [compose]. Unless otherwise specified, the latest
  stable version at the time of image building will be automatically picked up.
  At the time of writing, this installs the latest `2.x` branch, rewritten in
  golang, including the `docker-compose` compatibility [shim].
* An installation of `git` that is compatible with the github runner code.
  Unless otherwise specified, the latest stable [version][git-release] at the
  time of image building will be automatically picked up. This is because the
  default version available in Ubuntu is too old.
* The `build-essential` package, in order to facilitate compilation.

  [compose]: https://github.com/docker/compose
  [git-release]: https://launchpad.net/~git-core/+archive/ubuntu/ppa

## Releases

By default,the image follows the release tempo of the main [runner][release]
project. New images with the semantic version as a tag will be made available
shortly after a new [release] is made. There also exist tags that combine the
version of the runner and the short commit SHA of this project. These tags are
aimed at picking the proper combination, if necessary and when changes have been
applied to this project, which happens seldom. See
[here](.github/workflows/README.md) for more details.

## Known Limitations

### Logging

Containers created with this image will not have any log output. This is because
the runner (and the services that are started prior to the runner) are started
as systemd units. To get their logs, you will have to jump into the container,
and from an interactive shell (`bash` available) request for their logs through
`journalctl`. See [this](./systemd/README.md) for the list of relevant services.

### PV Mounts

When running from within kubernetes, you might not be able to use persistent
volumes, e.g. for the tool cache or the working directory. After some time, you
might loose the mount inside the container. This has been reported when `sysbox`
was installed on older kernels (Ubuntu 20.04 LTS) and with `shiftfs`. Using
local mounts, e.g. [`emptyDir`][emptyDir] works.

  [emptyDir]: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

### Coexistence of `sysbox` Containers

Our experience has shown that it is not always possible to run several `sysbox`
containers on the same Kubernetes node. To circumvent this limitation, you
should:

* Arrange for kubernetes to terminate Pods before is starts new ones (otherwise,
  there might be two Pods running on the same node during rollouts: one waiting
  to be up, and one still there, soon to be terminated).
* Force spreading your Pods across the nodes of your cluster.

To enforce termination, add the following snippet to your Deployment
specification:

```yaml
  strategy:
    type: Recreate
```

To enforce spreading across nodes, add the following snippet to your Pod
specification. This creates topology groups of one single member, per the name
of the node. You should adapt the label to whatever label you have chosen.

```yaml
      topologySpreadConstraints:
        -
          maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: gh-runner-sysbox
```

## Acknowledgments

This image takes a lot of inspiration from:

* The sysbox official [dockerfiles]: their content got slimmed down in the
  process in order to minimise the attack surface.
* [@efrecon]'s [fork] of the rootless Docker implementation of the runner. This
  runner provides an almost compatible API at the environment variable level.
* A [sysbox]-based [runner][sysbox-runner] implementation, similar in spirit,
  but seemly stale at the time of writing.

  [dockerfiles]: https://github.com/nestybox/dockerfiles
  [@efrecon]: https://github.com/efrecon
  [fork]: https://github.com/efrecon/github-actions-runner-rootless
  [sysbox-runner]: https://github.com/PasseiDireto/gh-runner

## Supported Arhitectures

Supported architectures are `amd64` (`x86_64`) and `arm64` (`aarch64`). This is
because these are the only two architectures for which the
[`compose-switch`][shim] project generates binaries for.
