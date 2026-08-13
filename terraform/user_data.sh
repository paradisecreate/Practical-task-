#!/bin/bash

set -e

# Clean DNF cache and refresh metadata
dnf clean all
rm -rf /var/cache/dnf
dnf makecache

# Install required packages
dnf install -y \
  git \
  java-21-amazon-corretto \
  wget \
  docker

# Start Docker
systemctl enable docker
systemctl start docker

# Add Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/rpm-stable/jenkins.repo

rpm --import \
  https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

# Refresh repositories
dnf clean all
dnf makecache

# Install Jenkins
dnf install -y jenkins

# Allow Jenkins to use Docker
usermod -aG docker jenkins

# Start Jenkins
systemctl enable jenkins
systemctl start jenkins