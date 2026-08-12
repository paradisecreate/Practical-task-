#!/bin/bash
set -e

echo "===== Starting EC2 bootstrap ====="

# Install Git and Ansible
dnf update -y
dnf install -y git ansible

# Move to /opt
cd /opt

# Clone the automation branch
git clone \
  --branch terraform-automation \
  --single-branch \
  https://github.com/paradisecreate/Practical-task-.git \
  bootstrap-repo

# Enter the repository we just cloned
cd /opt/bootstrap-repo

# Run the Ansible playbook
ansible-playbook ansible/playbook.yml

echo "===== EC2 bootstrap completed ====="