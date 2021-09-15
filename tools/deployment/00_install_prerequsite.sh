#!/usr/bin/env bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This downloads kind, puts it in a temp directory, and prints the directory
set -xe

export KIND_VERSION=${KIND_VERSION:="v0.11.1"}
export KIND_URL=${KIND_URL:="https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-$(uname)-amd64"}
export KUBE_VERSION=${KUBE_VERSION:="v1.18.6"}
export KUBE_URL=${KUBE_URL:="https://storage.googleapis.com"}
export HCO_WS=${HCO_WS:-$PWD}
export TMP_DIR=${TMP_DIR:-"$(dirname $(mktemp -u))"}

ANSIBLE_CFG=${ANSIBLE_CFG:-"${HOME}/.ansible.cfg"}
ANSIBLE_HOSTS=${ANSIBLE_HOSTS:-"${TMP_DIR}/ansible_hosts"}
PLAYBOOK_CONFIG=${PLAYBOOK_CONFIG:-"${TMP_DIR}/config.yaml"}

echo "Installing Necessary OS Packages"
pkg_check() {
  for pkg in $@; do
    sudo dpkg -s $pkg &> /dev/null || sudo DEBIAN_FRONTEND=noninteractive apt -y install $pkg
  done
}

pkg_check curl wget ca-certificates make

echo "Installing pip and dependencies"
curl -s https://bootstrap.pypa.io/get-pip.py | python3

echo "Installing Kind Version $KIND_VERSION"
sudo wget -O /usr/local/bin/kind ${KIND_URL}
sudo chmod +x /usr/local/bin/kind

# Install kubectl
echo "Installing Kubectl Version $KUBE_VERSION"
sudo wget -O /usr/local/bin/kubectl \
  "${KUBE_URL}"/kubernetes-release/release/"${KUBE_VERSION}"/bin/linux/amd64/kubectl

sudo chmod +x /usr/local/bin/kubectl

mkdir -p "$TMP_DIR"
envsubst <"${HCO_WS}/tools/deployment/config_template.yaml" > "$PLAYBOOK_CONFIG"

PACKAGES="ansible netaddr"
if [[ -z "${http_proxy}" ]]; then
  sudo python3 -m pip install $PACKAGES
else
  sudo python3 -m pip --proxy "${http_proxy}" install $PACKAGES
fi

echo "primary ansible_host=localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3" > "$ANSIBLE_HOSTS"
printf "[defaults]\nroles_path = %s/roles\n" "$HCO_WS" > "$ANSIBLE_CFG"

ansible-playbook -i "$ANSIBLE_HOSTS" \
  playbooks/airship-hostconfig-operator-deploy-docker.yaml \
  -e @"$PLAYBOOK_CONFIG"
