#!/bin/bash
set -e

echo "===== Starting EC2 setup ====="

# Install Git and Ansible
dnf update -y
dnf install -y git ansible

# Clone project
cd /opt

git clone \
  --branch terraform-automation \
  --single-branch \
  https://github.com/paradisecreate/Practical-task-.git bootstrap-repo

cd /opt/Practical-task-

# Run Ansible
ansible-playbook ansible/playbook.yml

echo "===== EC2 setup completed ====="