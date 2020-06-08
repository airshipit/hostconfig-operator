FROM quay.io/operator-framework/ansible-operator:v0.17.0

USER root
RUN dnf install openssh-clients -y
RUN yum install -y wget && wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && rpm -ivh epel-release-6-8.noarch.rpm && yum --enablerepo=epel -y install sshpass
USER ansible-operator

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible
COPY build/ansible.cfg /etc/ansible/ansible.cfg
COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
COPY playbook.yaml ${HOME}/
COPY inventory/ ${HOME}/inventory/
COPY plugins/ ${HOME}/plugins/
