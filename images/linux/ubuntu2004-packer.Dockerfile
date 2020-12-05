# syntax=docker/dockerfile:experimental
ARG OS_VERSION=20.04
FROM ubuntu:${OS_VERSION}

# > User account that will be used
ARG IMAGE_USER="runner"

# * Source the environment because it's not done automatically in Docker
RUN echo ". /etc/environment" >> /etc/profile

RUN if [ ! -f '/.dockerenv' ] ; then touch '/.dockerenv' ; fi

# * Important dependencies that needs to be satisfied before everything else
RUN apt-get -yq update && apt-get -yq install sudo

# > Set up non-root user with sudo privileges (https://stackoverflow.com/a/58151889)
RUN groupadd -g 1000 ${IMAGE_USER} && \
    useradd -u 1000 -g ${IMAGE_USER} -G sudo -m -s /bin/bash ${IMAGE_USER} && \
    sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' && \
    echo "${IMAGE_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "Customized the sudoers file for passwordless access to the ${IMAGE_USER} user!" && \
    echo "runner user:";  su - ${IMAGE_USER} -c id

USER ${IMAGE_USER}:${IMAGE_USER}
