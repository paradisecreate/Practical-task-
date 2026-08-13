#!/bin/bash

set -e

dnf update -y

# Install required packages
dnf install -y git java-21-amazon-corretto wget

# Install Docker
dnf install -y docker

systemctl enable docker
systemctl start docker

# Install Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/rpm-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

# Install Jenkins
dnf install -y jenkins

# Allow Jenkins to use Docker
usermod -aG docker jenkins

systemctl enable jenkins
systemctl start jenkins