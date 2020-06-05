FROM quay.io/operator-framework/ansible-operator:v0.17.0

RUN mkdir ${HOME}/.ssh
COPY build/id_rsa ${HOME}/.ssh/

USER root
RUN dnf install openssh-clients -y
RUN chown ansible-operator:root ${HOME}/.ssh/id_rsa
USER ansible-operator

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml
COPY ansible.cfg /etc/ansible/ansible.cfg

COPY roles/ ${HOME}/roles/
COPY playbook.yaml ${HOME}/
COPY inventory/ ${HOME}/inventory/
