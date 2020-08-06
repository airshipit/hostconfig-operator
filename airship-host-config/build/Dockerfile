FROM quay.io/operator-framework/ansible-operator:v0.17.0

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible
COPY build/ansible.cfg /etc/ansible/ansible.cfg
COPY watches.yaml ${HOME}/watches.yaml

USER root
RUN dnf install openssh-clients -y
RUN yum install -y wget && wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && rpm -ivh epel-release-6-8.noarch.rpm && yum --enablerepo=epel -y install sshpass
USER ansible-operator

COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
COPY inventory/ ${HOME}/inventory/
COPY plugins/ ${HOME}/plugins/
# ansible-runner unable to pick custom callback plugins specified in any other directory other than /usr/local/lib/python3.6/site-packages/ansible/plugins/callback
# ansible-runner is overriding the ANSIBLE_CALLBACK_PLUGINS Environment variable
# https://github.com/ansible/ansible-runner/blob/stable/1.3.x/ansible_runner/runner_config.py#L178
COPY plugins/callback/hostconfig_k8_cr_status.py /usr/local/lib/python3.6/site-packages/ansible/plugins/callback/
RUN mkdir ${HOME}/.ssh
