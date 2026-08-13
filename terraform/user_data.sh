#!/bin/bash

set -e

dnf update -y

dnf install -y \
  git \
  java-21-amazon-corretto \
  wget \
  docker

systemctl enable docker
systemctl start docker

wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/rpm-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

dnf install -y jenkins

usermod -aG docker jenkins

systemctl enable jenkins
systemctl start jenkins