#!/bin/bash

set -e

exec > /var/log/user-data.log 2>&1

echo "Starting bootstrap..."

dnf install -y \
  git \
  python3 \
  python3-pip

pip3 install --no-cache-dir ansible

rm -rf /opt/practical-task

git clone \
  --branch terraform-automation \
  https://github.com/paradisecreate/Practical-task-.git \
  /opt/practical-task

cd /opt/practical-task

ansible-playbook \
  -i localhost, \
  -c local \
  ansible/playbook.yml

echo "Bootstrap finished."