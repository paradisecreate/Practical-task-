#!/bin/bash

set -e

echo "=== Updating system ==="
sudo dnf update -y

echo "=== Installing Git ==="
sudo dnf install -y git

echo "=== Installing Docker ==="
sudo dnf install -y docker

echo "=== Starting Docker ==="
sudo systemctl enable docker
sudo systemctl start docker

echo "=== Adding user to Docker group ==="
sudo usermod -aG docker ec2-user

echo "=== Installation completed ==="

docker --version
git --version