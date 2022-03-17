FROM ubuntu:focal


# When latest, will pick latest official release
ARG GH_RUNNER_VERSION="latest"

# Versions for Docker compose (and shim) releases. When latest, will pick latest
# stable release at the time of the build.
ARG COMPOSE_VERSION=latest
ARG COMPOSE_SWITCH_VERSION=latest

# Copy our "library" and all necessary shell-wrappers. Note that some of the
# wrappers that we install will be used to build the image itself, i.e. as part
# of some of the `RUN` commands below.
COPY lib/*.sh /usr/local/share/runner/
COPY *.sh /usr/local/bin/


# Build arguments for OCI-oriented information
ARG OCI_GITHUB=https://github.com/Mitigram/gh-runner-sysbox
ARG OCI_ORG=Mitigram
ARG OCI_SHA=
ARG OCI_BRANCH=main
ARG OCI_DOCKERFILE=Dockerfile
ARG OCI_RFC3339=

# Dynamic OCI Labels
LABEL org.opencontainers.image.authors="Emmanuel Frécon <https://github.com/efrecon>"
LABEL org.opencontainers.image.url="${OCI_GITHUB}"
LABEL org.opencontainers.image.documentation="${OCI_GITHUB}"
LABEL org.opencontainers.image.source="${OCI_GITHUB}/blob/${OCI_BRANCH}/${OCI_DOCKERFILE}"
LABEL org.opencontainers.image.vendor="${OCI_ORG}"
LABEL org.opencontainers.image.version="${GH_RUNNER_VERSION}"
LABEL org.opencontainers.image.revision="${OCI_SHA}"
LABEL org.opencontainers.image.license="MIT"
LABEL org.opencontainers.image.title="sysbox GitHub Runner"
LABEL org.opencontainers.image.description="Dockerised GitHub Actions self-hosted runner using ubuntu and tuned for sysbox containers"
LABEL org.opencontainers.image.created="${OCI_RFC3339}"

#
# Systemd installation
#
RUN apt-install.sh                               \
            systemd                              \
            systemd-sysv                         \
            libsystemd0                          \
            ca-certificates                      \
            dbus                                 \
            iptables                             \
            iproute2                             \
            kmod                                 \
            locales                              \
            sudo                                 \
            udev &&                              \
                                                 \
    # Prevents journald from reading kernel messages from /dev/kmsg
    echo "ReadKMsg=no" >> /etc/systemd/journald.conf &&               \
                                                                      \
    apt-clean.sh

# Make use of stopsignal (instead of sigterm) to stop systemd containers.
STOPSIGNAL SIGRTMIN+3

# install Docker and other dependencies ((latest) git, jq, curl, etc.)
RUN apt-install.sh                                                    \
       apt-transport-https                                            \
       build-essential                                                \
       ca-certificates                                                \
       curl                                                           \
       gnupg-agent                                                    \
       jq                                                             \
       software-properties-common                                     \
       wget &&                                                        \
                                                                      \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg           \
         | apt-key add - &&                                           \
    apt-key fingerprint 0EBFCD88 &&                                   \
    add-apt-repository                                                \
       "deb [arch=$(arch.sh -e 1)] https://download.docker.com/linux/ubuntu     \
       $(lsb_release -cs)                                             \
       stable" &&                                                     \
    apt-install.sh                                                    \
       docker-ce docker-ce-cli containerd.io &&                       \
                                                                      \
    add-apt-repository ppa:git-core/ppa &&                            \
    apt-install.sh git &&                                             \
                                                                      \
    apt-clean.sh

# Install Docker compose. Turn on compatibility mode when installing newer 2.x
# branch.
RUN install-compose.sh -c "$COMPOSE_VERSION" -s "${COMPOSE_SWITCH_VERSION}"

# Add and config `runner` user as sudo, arrange for members of sudo group to
# skip password auth.
RUN useradd -m runner \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

WORKDIR /actions-runner
RUN chown runner:runner /actions-runner
USER runner
RUN install-runner.sh -v "${GH_RUNNER_VERSION}"
USER root
RUN ./bin/installdependencies.sh

# Copy and schedule service units
COPY systemd/runner*.service /lib/systemd/system/
RUN for s in systemd/runner*.service; do \
      ln -sf \
        /lib/systemd/system/$(basename "$s") \
        /etc/systemd/system/multi-user.target.wants/; \
    done

# Set systemd as entrypoint. There will hardly be any logs, use `journalctl`
# from within instead.
ENTRYPOINT [ "/sbin/init", "--log-level=err" ]
