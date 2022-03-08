# Auto Releasing

The workflow `autorelease.yml` in this directory arranges to automatically make
releases of the project. These releases follows the release tempo of the main
[runner] project. When a new release for the runner is detected, i.e. whenever
there is no Docker image with the same tag within this repository, a new image
is built. This is checked once per day.

Once a new image has been generated successfully:

+ The latest [runner] release tag is detected.
+ The latest release of this project is detected.
+ When the semantic versions of these two projects differs, a new release is
  made and will point to the image generated as described above.

Auto releasing uses a reusable and flexible [workflow](./_release.yml). This is
mainly for historical reasons, but the workflow is also used for
[manual](#manual-release) releases.

  [runner]: https://github.com/actions/runner/releases

## Removing

If you wanted to manually re-create all images for a given release, perform the
following operations:

+ Remove the release from the list of releases for this project.
+ Remove the tag at the origin, e.g. `git push --delete origin 2.286.0`.

Once you have cleaned up, it is possible to manually re-run the workflow from
the GitHub UI.

## Manual Release

It is possible to manually release, back in time, if necessary. This is handled
by the `manual.yml` workflow. You can interact with it from the GitHub actions
UI. The workflow takes the SemVer for the `runner` as an input. As the version
for `git` and `docker compose` are picked at runtime, releasing back in time is
not exact as it might generate images with dependencies that would have not
existed at the time of the `runner` release.
