#!/bin/bash

# Root User Config
ROOT_PW='RootChangeMe!'
Root_SSH=''

# Packer User Config
PACKER_PW='packer'
PACKER_SSH=''

# Root Actual Configuration
mkdir -p /root/.ssh/
echo $ROOT_SSH >> /root/.ssh/authorized_keys
echo root:$ROOT_PW | /usr/sbin/chpasswd

# Actual Otto Configuration
mkdir -p /home/packer/.ssh
echo $PACKER_SSH >> /home/packer/.ssh/authorized_keys
chown packer:packer /home/packer/.ssh/authorized_keys
chown packer:packer /home/packer/.ssh
echo packer:$PACKER_PW | /usr/sbin/chpasswd

# OpenSSH Config
mkdir /etc/ssh/old_keys
mv /etc/ssh/ssh_host_* /etc/ssh/old_keys
dpkg-reconfigure openssh-server
sed -i 's/*PermitRootLogin*/PermitRootLogin\ without-password/g' /etc/ssh/sshd_config