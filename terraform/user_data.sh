#!/bin/bash

set -euxo pipefail

exec > >(tee /var/log/user-data.log) 2>&1

echo "=== BOOTSTRAP START ==="

dnf install -y \
  git \
  python3 \
  python3-pip

python3 -m pip install \
  --no-cache-dir \
  ansible-core

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