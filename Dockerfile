# Ansible Operator base image
FROM quay.io/operator-framework/ansible-operator:v0.17.0

# Installing dependency libraries
COPY airship-host-config/requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

# Installing ssh clients - used to connect to kubernetes nodes
USER root
RUN rpm -ivh https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN dnf install dbus libnghttp2 python3-librepo dbus-libs librepo dbus-daemon \
     gnutls dbus-common dbus-tools systemd python3-libxml2 cryptsetup-libs libssh \
     libarchive cyrus-sasl-lib curl openssl-libs platform-python glibc systemd-pam \
     platform-python-pip python3-pip libcom_err gnupg2 vim-minimal libstdc++ \
     python3-libs systemd-libs libssh-config glib2 python3-pip-wheel libsolv \
     gdb-gdbserver sqlite-libs libgcrypt libgcc pcre2 glibc-common expat libxml2 \
     libcurl glibc-minimal-langpack libpcap openssh-clients sshpass -y
USER ansible-operator

# Configuration for ansible
COPY airship-host-config/build/ansible.cfg /etc/ansible/ansible.cfg

# CRD entrypoint definition YAML file
COPY airship-host-config/watches.yaml ${HOME}/watches.yaml

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

# Copying scripts folder used by exec configuration
COPY airship-host-config/scripts/ ${HOME}/scripts/

# Intializing ssh folder
RUN mkdir ${HOME}/.ssh
