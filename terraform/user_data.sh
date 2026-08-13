#!/bin/bash
set -eux

exec > >(tee /var/log/user-data.log) 2>&1

echo "=== BOOTSTRAP START ==="

dnf install -y git python3-pip

pip3 install ansible

rm -rf /opt/practical-task

git clone \
  --depth 1 \
  --branch "${branch}" \
  "${repository}" \
  /opt/practical-task

cd /opt/practical-task

ansible-playbook \
  -i "localhost," \
  -c local \
  ansible/playbook.yml

echo "=== BOOTSTRAP COMPLETE ==="