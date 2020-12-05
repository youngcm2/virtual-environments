# syntax=docker/dockerfile:experimental
ARG OS_VERSION=20.04
FROM ubuntu:${OS_VERSION}

# > Both needs to be set to proper version
ARG OS_VERSION="20.04"
ARG OSVERSION="2004"
# > Me
ARG IMAGE_MAINTAINER="me@hackerc.at"
# > Variables from ubuntu****.json
ARG IMAGE_FOLDER="/imagegeneration"
ARG IMAGEDATA_FILE="${IMAGE_FOLDER}/imagedata.json"
ARG GO_VERSION="1.14"
ARG GO_DEFAULT="1.14"
ARG HELPER_SCRIPT_FOLDER="${IMAGE_FOLDER}/helpers"
ARG INSTALLER_SCRIPT_FOLDER="${IMAGE_FOLDER}/installers"
ARG IMAGE_VERSION="dev"
ARG IMAGE_OS="ubuntu20"
ARG BUILD="dev"
# > User account that will be used
ARG IMAGE_USER="runner"

# > make apt noninteractive
ARG DEBIAN_FRONTEND="noninteractive"

# > Labels
LABEL maintainer=${IMAGE_MAINTAINER}
LABEL build=${BUILD}

# > Env variables required for build
ENV BUILD=${BUILD}
ENV OS_VERSION=${OS_VERSION}
ENV OSVERSION=${OSVERSION}
ENV IMAGE_OS=${IMAGE_OS}
ENV LSB_RELEASE=${OS_VERSION}
ENV IMAGE_FOLDER=${IMAGE_FOLDER}
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
ENV HELPER_SCRIPTS=${HELPER_SCRIPT_FOLDER}
ENV INSTALLER_SCRIPT_FOLDER=${INSTALLER_SCRIPT_FOLDER}
ENV IMAGE_VERSION=${IMAGE_VERSION}
ENV IMAGEDATA_FILE=${IMAGEDATA_FILE}

RUN echo "BUILD=${BUILD}" >> /etc/environment
RUN echo "OS_VERSION=${OS_VERSION}" >> /etc/environment
RUN echo "IMAGE_OS=${IMAGE_OS}" >> /etc/environment
RUN echo "OSVERSION=${OSVERSION}" >> /etc/environment
RUN echo "LSB_RELEASE=${OS_VERSION}" >> /etc/environment
RUN echo "IMAGE_FOLDER=${IMAGE_FOLDER}" >> /etc/environment
RUN echo "AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache" >> /etc/environment
RUN echo "HELPER_SCRIPTS=${HELPER_SCRIPT_FOLDER}" >> /etc/environment
RUN echo "INSTALLER_SCRIPT_FOLDER=${INSTALLER_SCRIPT_FOLDER}" >> /etc/environment
RUN echo "IMAGE_VERSION=${IMAGE_VERSION}" >> /etc/environment
RUN echo "IMAGEDATA_FILE=${IMAGEDATA_FILE}" >> /etc/environment

# > Set workdir to tmp
WORKDIR /tmp/workdir

# * Source the environment because it's not done automatically in Docker
RUN echo ". /etc/environment" >> /etc/profile

RUN if [ ! -f '/.dockerenv' ] ; then touch '/.dockerenv' ; fi

# * Important dependencies that needs to be satisfied before everything else
RUN apt-get -yq update && apt-get -yq install lsb-release sudo rsync wget

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

# > Copy required files to build container
COPY --chown=1000:1000 ./scripts         /tmp/scripts
COPY --chown=1000:1000 ./config          /tmp/config
COPY --chown=1000:1000 ./toolsets        /tmp/toolsets
COPY --chown=1000:1000 ./post-generation /tmp/post-generation

RUN chmod -R +x /tmp/scripts/

# > Create image directory with proper permissions
RUN sudo mkdir -p ${IMAGE_FOLDER} && \
    sudo chown 1000:1000 ${IMAGE_FOLDER} && \
    sudo chmod 0777 ${IMAGE_FOLDER}

# * Base
RUN ls -lah /tmp/scripts/base && sudo /tmp/scripts/base/apt-mock.sh
RUN sudo /tmp/scripts/base/repos.sh
RUN sudo /tmp/scripts/base/apt.sh
RUN sudo /tmp/scripts/base/limits.sh

RUN cp -r /tmp/scripts/helpers $HELPER_SCRIPTS && \
    cp -r /tmp/scripts/installers $INSTALLER_SCRIPT_FOLDER && \
    cp -r /tmp/post-generation $IMAGE_FOLDER && \
    cp -r /tmp/scripts/SoftwareReport $IMAGE_FOLDER && \
    cp -r /tmp/toolsets/toolset-$OSVERSION.json $INSTALLER_SCRIPT_FOLDER/toolset.json

RUN sudo /tmp/scripts/installers/preimagedata.sh
RUN sudo /tmp/scripts/installers/configure-environment.sh
RUN sudo /tmp/scripts/installers/complete-snap-setup.sh

# * Software install
RUN sudo /tmp/scripts/installers/7-zip.sh
RUN sudo /tmp/scripts/installers/ansible.sh
RUN sudo /tmp/scripts/installers/azcopy.sh
RUN sudo /tmp/scripts/installers/azure-cli.sh
RUN sudo /tmp/scripts/installers/azure-devops-cli.sh
# * This step installs a lot of basic tools required for next steps
RUN sudo /tmp/scripts/installers/basic.sh
RUN sudo /tmp/scripts/installers/aliyun-cli.sh
RUN sudo /tmp/scripts/installers/aws.sh
RUN sudo /tmp/scripts/installers/build-essential.sh
RUN sudo /tmp/scripts/installers/clang.sh
RUN sudo /tmp/scripts/installers/swift.sh
RUN sudo /tmp/scripts/installers/cmake.sh
RUN sudo /tmp/scripts/installers/codeql-bundle.sh
RUN sudo /tmp/scripts/installers/containers.sh
RUN sudo /tmp/scripts/installers/docker-compose.sh
# TODO: Allow running Docker in Docker
#RUN --security=insecure /tmp/scripts/installers/docker-moby.sh
RUN sudo /tmp/scripts/installers/docker-moby.sh
RUN sudo /tmp/scripts/installers/dotnetcore-sdk.sh
RUN sudo /tmp/scripts/installers/erlang.sh
RUN sudo /tmp/scripts/installers/firefox.sh
RUN sudo /tmp/scripts/installers/gcc.sh
RUN sudo /tmp/scripts/installers/gfortran.sh
RUN sudo /tmp/scripts/installers/git.sh
RUN sudo /tmp/scripts/installers/github-cli.sh
RUN sudo /tmp/scripts/installers/google-chrome.sh
RUN sudo /tmp/scripts/installers/google-cloud-sdk.sh
RUN sudo /tmp/scripts/installers/haskell.sh
RUN sudo /tmp/scripts/installers/heroku.sh
RUN sudo /tmp/scripts/installers/hhvm.sh
RUN sudo /tmp/scripts/installers/image-magick.sh
RUN sudo /tmp/scripts/installers/java-tools.sh
RUN sudo /tmp/scripts/installers/kind.sh
RUN sudo /tmp/scripts/installers/kubernetes-tools.sh
RUN sudo /tmp/scripts/installers/oc.sh
RUN sudo /tmp/scripts/installers/leiningen.sh
RUN sudo /tmp/scripts/installers/mercurial.sh
RUN sudo /tmp/scripts/installers/miniconda.sh
RUN sudo /tmp/scripts/installers/mono.sh
RUN sudo /tmp/scripts/installers/mysql.sh
RUN sudo /tmp/scripts/installers/mssql-cmd-tools.sh
RUN sudo /tmp/scripts/installers/nvm.sh
RUN sudo /tmp/scripts/installers/nodejs.sh
RUN sudo /tmp/scripts/installers/bazel.sh
RUN sudo /tmp/scripts/installers/oras-cli.sh
RUN sudo /tmp/scripts/installers/phantomjs.sh
RUN sudo /tmp/scripts/installers/php.sh
RUN sudo /tmp/scripts/installers/pollinate.sh
RUN sudo /tmp/scripts/installers/postgresql.sh
RUN sudo /tmp/scripts/installers/powershellcore.sh

# * Add sourcing the environment for PowerShell
RUN sudo mkdir -p /opt/microsoft/powershell/7/ && \
    sudo mkdir -p /opt/microsoft/powershell/6/ && \
    echo 'Get-Content /etc/environment | ForEach-Object -Process { $EnvVariable = $_ -split "=" ; Set-Item -LiteralPath ("env:/" + $EnvVariable[0]) -Value $EnvVariable[1] }' | sudo tee -a /opt/microsoft/powershell/7/Microsoft.PowerShell_profile.ps1 /opt/microsoft/powershell/6/Microsoft.PowerShell_profile.ps1

# * Software install
RUN sudo /tmp/scripts/installers/pulumi.sh
RUN sudo /tmp/scripts/installers/ruby.sh
RUN sudo /tmp/scripts/installers/r.sh
RUN sudo /tmp/scripts/installers/rust.sh
RUN sudo /tmp/scripts/installers/julia.sh
RUN sudo /tmp/scripts/installers/sbt.sh
RUN sudo /tmp/scripts/installers/selenium.sh
RUN sudo /tmp/scripts/installers/sphinx.sh
RUN sudo /tmp/scripts/installers/subversion.sh
RUN sudo /tmp/scripts/installers/terraform.sh
RUN sudo /tmp/scripts/installers/packer.sh
RUN sudo /tmp/scripts/installers/vcpkg.sh
RUN sudo /tmp/scripts/installers/vercel.sh
RUN sudo /tmp/scripts/installers/dpkg-config.sh
RUN sudo /tmp/scripts/installers/mongodb.sh
RUN sudo /tmp/scripts/installers/rndgenerator.sh
RUN sudo /tmp/scripts/installers/swig.sh
RUN sudo /tmp/scripts/installers/netlify.sh
RUN sudo /tmp/scripts/installers/android.sh
RUN sudo /tmp/scripts/installers/azpowershell.sh
RUN sudo /tmp/scripts/installers/pypy.sh
RUN sudo /tmp/scripts/installers/python.sh

# * Toolset
RUN sudo /bin/sh -c -- pwsh -Command "/tmp/scripts/installers/Install-Toolset.ps1"
RUN sudo /bin/sh -c -- pwsh -Command "/tmp/scripts/installers/Configure-Toolset.ps1"
RUN sudo /bin/sh -c -- pwsh -Command "/tmp/scripts/installers/Validate-Toolset.ps1"

RUN sudo /tmp/scripts/installers/pipx-packages.sh
RUN /tmp/scripts/installers/homebrew.sh
# * Doesn't work currently
#RUN /tmp/scripts/installers/homebrew-validate.sh

RUN sudo /tmp/scripts/base/apt-mock-remove.sh

RUN sudo /bin/sh -c -- pwsh -Command "/tmp/scripts/installers/Install-PowerShellModules.ps1"

# TODO: Fix environment variables not being available in PowerShell
# ! PowerShell Bug: Environment is not loaded from profile when running with -File parameter
RUN /bin/sh -c -- pwsh -Command "${IMAGE_FOLDER}/SoftwareReport/SoftwareReport.Generator.ps1 -OutputDirectory ${IMAGE_FOLDER}"

# * Currently cannot copy from build container to host
#RUN ls ${IMAGE_FOLDER} && cp ${IMAGE_FOLDER}/Ubuntu${OSVERSION}-README.md ${IMAGE_FOLDER}/Ubuntu-Readme.md

RUN sudo /tmp/scripts/installers/post-deployment.sh

RUN sudo cp /tmp/config/ubuntu${OSVERSION}.conf /tmp/

RUN sudo mkdir -p /etc/vsts && sudo cp /tmp/ubuntu${OSVERSION}.conf /etc/vsts/machine_instance.conf

RUN sudo /tmp/scripts/installers/cleanup.sh

WORKDIR /github/runner
VOLUME /github/runner
# * Required to inherit environment
ENTRYPOINT [ "/bin/bash", "--login" ]
