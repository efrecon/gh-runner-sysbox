FROM ubuntu:focal


# When latest, will pick latest official release
ARG GH_RUNNER_VERSION="latest"

# Versions for Docker compose (and shim) releases. When latest, will pick latest
# stable release at the time of the build.
ARG COMPOSE_VERSION=latest
ARG COMPOSE_SWITCH_VERSION=latest

COPY *.sh /usr/local/bin/

#
# Systemd installation
#
RUN apt-get update &&                            \
    apt-get install -y --no-install-recommends   \
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

# install Docker and other dependencies
RUN apt-get update && apt-get install --no-install-recommends -y      \
       apt-transport-https                                            \
       ca-certificates                                                \
       curl                                                           \
       gnupg-agent                                                    \
       jq                                                             \
       software-properties-common &&                                  \
                                                                      \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg           \
         | apt-key add - &&                                           \
	                                                                    \
    apt-key fingerprint 0EBFCD88 &&                                   \
                                                                      \
    add-apt-repository                                                \
       "deb [arch=amd64] https://download.docker.com/linux/ubuntu     \
       $(lsb_release -cs)                                             \
       stable" &&                                                     \
                                                                      \
    apt-get update && apt-get install --no-install-recommends -y      \
       docker-ce docker-ce-cli containerd.io &&                       \
                                                                      \
    add-apt-repository ppa:git-core/ppa &&                            \
    apt-get update && apt-get install --no-install-recommends -y      \
       git &&                                                         \
                                                                      \
    apt-clean.sh

# Install Docker compose. Turn on compatibility mode when installing newer 2.x
# branch.
RUN install-compose.sh -c "$COMPOSE_VERSION" -s "${COMPOSE_SWITCH_VERSION}"

# Add and config runner user as sudo
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

COPY runner.service /lib/systemd/system/
RUN ln -sf /lib/systemd/system/runner.service                    \
       /etc/systemd/system/multi-user.target.wants/runner.service

# Set systemd as entrypoint.
ENTRYPOINT [ "/sbin/init", "--log-level=err" ]
