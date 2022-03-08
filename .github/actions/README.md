# Internal Actions

This directory contains a number of internal actions, called from both the main
and reusable workflows. The actions are documented within their YAML description
and commented. Available actions are:

+ [`presence`](./presence/action.yml) actively test if an image exists at a
  (remote) Docker registry.
+ [`version`](./version/action.yml) actively request a public GitHub project for
  its latest, stable released version. The action scrapes the HTML to avoid API
  rate limitations. The action returns a pure SemVer, i.e. `major.minor.patch`,
  without any leading `v` letter.
+ [`image`](./image/action.yml) builds an image from a various `Dockerfile`s at
  the root of the project, and publish it to both the GitHub Container Registry,
  and the DockerHub (provided proper credentials are passed to the action). The
  action injects build arguments to carry in build-time information if
  necessary.
