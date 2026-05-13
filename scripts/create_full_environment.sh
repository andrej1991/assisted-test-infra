#!/usr/bin/env bash

set -o errexit

export PATH=${PATH}:/usr/local/bin


function error() {
    echo $@ 1>&2
}

# Check OS
OS=$(awk -F= '/^ID=/ { print $2 }' /etc/os-release | tr -d '"')
if [[ ! ${OS} =~ ^(ol)$ ]] && [[ ! ${OS} =~ ^(centos)$ ]] && [[ ! ${OS} =~ ^(rhel)$ ]] && [[ ! ${OS} =~ ^(rocky)$ ]] && [[ ! ${OS} =~ ^(almalinux)$ ]]; then
    error "\"${OS}\" is an unsupported OS. We support only CentOS, RHEL, Rocky or AlmaLinux."
    error "It's not recommended to run the code in this repo locally on your personal machine, as it makes some opinionated configuration changes to the machine it's running on"
    exit 1
fi

#Check CentOS version
VER=$(awk -F= '/^VERSION_ID=/ { print $2 }' /etc/os-release | tr -d '"' | cut -f1 -d'.')
SUPPORTED_VERSIONS=( 8 9 10 )
if [[ ! " ${SUPPORTED_VERSIONS[@]} " =~ " ${VER} " ]]; then
    if [[ ${OS} =~ ^(centos)$ ]]; then
        error "CentOS / CentOS Stream major version 8, 9, or 10 is required."
    elif [[ ${OS} =~ ^(rhel)$ ]]; then
        error "RHEL major version 8, 9, or 10 is required."
    elif [[ ${OS} =~ ^(rocky)$ ]]; then
        error "Rocky Linux major version 8, 9, or 10 is required."
    elif [[ ${OS} =~ ^(almalinux)$ ]]; then
        error "AlmaLinux major version 8, 9, or 10 is required."
    else
        error "Major OS version ${VER} is not supported (expected one of: ${SUPPORTED_VERSIONS[*]})."
    fi
    exit 1
fi

echo "Installing environment"
scripts/install_environment.sh
echo "Done installing"

echo "Installing kind"
make bring_assisted_service
assisted-service/hack/kind/kind.sh install
echo "Done installing kind"

echo "Installing minikube"
assisted-service/hack/minikube/minikube.sh install
echo "Done installing minikube"

echo "Installing oc and kubectl"
scripts/install_k8s_clients.sh
echo "Done installing oc and kubectl"

echo "Creating image"
make image_build
echo "Done creating image"

if [ "${DEPLOY_TARGET}" == "minikube" ] && [ -z "${NO_MINIKUBE}" ]; then
    echo "Start minikube"
    make start_minikube
fi
