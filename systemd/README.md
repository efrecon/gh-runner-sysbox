# `systemd` units

This directory contains the variour `systemd` services that are installed and
enabled at the runner. These are (in order of execution):

+ `runner-conf` will steal most of the environment of the main process, i.e.
  `systemd` itself and propagate this environment to a file, so that it can be
  picked up by other services below. This complexity is necessary in order to
  support the configuration of the runner from environment variables. When
  `systemd` units are started, they always start from a clean environment, so we
  need a mechanism to capture the environment of the main process, which is set
  at startup by the container runtime. Implementation is through
  [`export.sh`](../export.sh).
+ `runner-preflight` inherits the environment from above and runs executables
  pointed at by the `RUNNER_PREFLIGHT_PATH` variable. These will be run by the
  `runner` user, meaning that you will have to `sudo` if you want to perform
  "system" work. As this runs before the Docker daemon is started, it is
  possible to amend/install Docker settings at this point, but also to install
  other services, libraries, packages that would be necessary for the runner.
  Implementation is through [`hook.sh`](../hook.sh).
+ `runner` is the main service and in charge of starting the runner. The service
  will pick the environment from above (first service) and start the runner, via
  [`runner.sh`](../runner.sh), as the `runner` user.

## File Access Mode

The unit in charge for stealing the configuration restricts the copy of the
environment to only be accessible to the `runner` user. Other units, instead,
will relax so that all members of the group `runner` also have access to the
files/directories created from sub-processes of the unit. This is to facilitate
usage in `sysbox` when `shiftfs` is turned off.
