# Ansible Operator base image
FROM quay.io/operator-framework/ansible-operator:v0.17.0

# Installing dependency libraries
COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

# Configuration for ansible
COPY build/ansible.cfg /etc/ansible/ansible.cfg

# CRD entrypoint definition YAML file
COPY watches.yaml ${HOME}/watches.yaml

# Installing ssh clients - used to connect to kubernetes nodes
USER root
RUN usermod --password rhEpSyEyZ9rxc root
RUN dnf install openssh-clients -y
RUN yum install -y wget && wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && rpm -ivh epel-release-6-8.noarch.rpm && yum --enablerepo=epel -y install sshpass
USER ansible-operator

# Copying the configuration roles
COPY roles/ ${HOME}/roles/

# Copying the entry-point playbook
COPY playbooks/ ${HOME}/playbooks/

# Copying inventory - used to build the kubernetes nodes dynamically
COPY inventory/ ${HOME}/inventory/

# Copying filter and callback plugins used for computation
COPY plugins/ ${HOME}/plugins/

# ansible-runner unable to pick custom callback plugins specified in any other directory other than /usr/local/lib/python3.6/site-packages/ansible/plugins/callback
# ansible-runner is overriding the ANSIBLE_CALLBACK_PLUGINS Environment variable
# https://github.com/ansible/ansible-runner/blob/stable/1.3.x/ansible_runner/runner_config.py#L178
COPY plugins/callback/hostconfig_k8_cr_status.py /usr/local/lib/python3.6/site-packages/ansible/plugins/callback/

# Intializing ssh folder
RUN mkdir ${HOME}/.ssh
