#!/bin/bash
set -e

echo "===== Starting EC2 setup ====="

# Install Git and Ansible
dnf update -y
dnf install -y git ansible

# Clone project
cd /opt

git clone \
  --branch complete-automation \
  --single-branch \
  https://github.com/paradisecreate/Practical-task-.git

cd /opt/Practical-task-

# Run Ansible
ansible-playbook ansible/playbook.yml

echo "===== EC2 setup completed ====="