# Ansible Operator base image
FROM quay.io/operator-framework/ansible-operator:v0.17.0

# Installing dependency libraries
COPY airship-host-config/requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

# Configuration for ansible
COPY airship-host-config/build/ansible.cfg /etc/ansible/ansible.cfg

# CRD entrypoint definition YAML file
COPY airship-host-config/watches.yaml ${HOME}/watches.yaml

# Installing ssh clients - used to connect to kubernetes nodes
USER root
RUN dnf install openssh-clients -y
RUN rpm -ivh https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm \
     && dnf -y install sshpass
USER ansible-operator

# Copying the configuration roles
COPY airship-host-config/roles/ ${HOME}/roles/

# Copying the entry-point playbook
COPY airship-host-config/playbooks/ ${HOME}/playbooks/

# Copying inventory - used to build the kubernetes nodes dynamically
COPY airship-host-config/inventory/ ${HOME}/inventory/

# Copying filter and callback plugins used for computation
COPY airship-host-config/plugins/ ${HOME}/plugins/

# ansible-runner unable to pick custom callback plugins specified in any other directory other than /usr/local/lib/python3.6/site-packages/ansible/plugins/callback
# ansible-runner is overriding the ANSIBLE_CALLBACK_PLUGINS Environment variable
# https://github.com/ansible/ansible-runner/blob/stable/1.3.x/ansible_runner/runner_config.py#L178
COPY airship-host-config/plugins/callback/hostconfig_k8_cr_status.py /usr/local/lib/python3.6/site-packages/ansible/plugins/callback/

# Intializing ssh folder
RUN mkdir ${HOME}/.ssh
