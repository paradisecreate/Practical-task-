#!/bin/bash

set -euxo pipefail

exec > >(tee /var/log/user-data.log) 2>&1

echo "=== BOOTSTRAP START ==="

# --------------------------------------------------
# Keep SSM available
# --------------------------------------------------

systemctl enable amazon-ssm-agent || true
systemctl start amazon-ssm-agent || true

# --------------------------------------------------
# Add swap for t3.micro
# --------------------------------------------------

if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
fi

swapon /swapfile || true

if ! grep -q "^/swapfile " /etc/fstab; then
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

free -h

# --------------------------------------------------
# Bootstrap requirements
# --------------------------------------------------

dnf install -y \
    git \
    python3 \
    python3-pip

python3 -m pip install \
    --no-cache-dir \
    ansible-core

# --------------------------------------------------
# Get project
# --------------------------------------------------

rm -rf /opt/practical-task

git clone \
    --depth 1 \
    --branch "${branch}" \
    "${repository}" \
    /opt/practical-task

cd /opt/practical-task

# --------------------------------------------------
# Configure instance
# --------------------------------------------------

ansible-playbook \
    -i "localhost," \
    -c local \
    ansible/playbook.yml

echo "=== BOOTSTRAP COMPLETE ==="