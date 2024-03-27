FROM registry.access.redhat.com/ubi8-minimal

CMD ["gradle"]

ENV GRADLE_HOME /opt/gradle

#Install Java runtime
RUN set -o errexit -o nounset \
    && microdnf -y upgrade --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0 \
    && microdnf install -y java-1.8.0-openjdk-devel unzip shadow-utils which curl git --nodocs --setopt=install_weak_deps=0 \
    && microdnf clean all

RUN set -o errexit -o nounset \
    && echo "Adding gradle user and group" \
    && groupadd --system --gid 1000 gradle \
    && useradd --system --gid gradle --uid 1000 --shell /bin/bash --create-home gradle \
    && mkdir /home/gradle/.gradle \
    && chown --recursive gradle:gradle /home/gradle \
    && chmod --recursive o+rwx /home/gradle \
    \
    && echo "Symlinking root Gradle cache to gradle Gradle cache" \
    && ln --symbolic /home/gradle/.gradle /root/.gradle

VOLUME /home/gradle/.gradle

WORKDIR /home/gradle

ENV GRADLE_VERSION 6.9.3
ARG GRADLE_DOWNLOAD_SHA256=dcf350b8ae1aa192fc299aed6efc77b43825d4fedb224c94118ae7faf5fb035d
RUN set -o errexit -o nounset \
    && echo "Downloading Gradle" \
    && curl -L "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o gradle.zip \
    \
    && echo "Checking Gradle download hash" \
    && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - \
    \
    && echo "Installing Gradle" \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle

USER gradle

RUN export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))" && echo $JAVA_HOME

RUN set -o errexit -o nounset \
    && echo "Testing Gradle installation" \
    && gradle --version

USER root
