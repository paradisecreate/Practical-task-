#!/bin/bash
# Configured with consulting of ChatGPT
set -e

echo "=== 1. Detecting Linux distribution ==="
cat /etc/os-release

echo
echo "=== 2. Installing required packages ==="

if command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y curl unzip git
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y curl unzip git
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y curl unzip git
else
    echo "Unsupported Linux package manager"
    exit 1
fi

echo
echo "=== 3. Installing AWS CLI v2 if missing ==="

if ! command -v aws >/dev/null 2>&1; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
else
    echo "AWS CLI already installed"
fi

aws --version

echo
echo "=== 4. Installing Terraform if missing ==="

if ! command -v terraform >/dev/null 2>&1; then
    TERRAFORM_VERSION="1.12.2"

    curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    sudo mv terraform /usr/local/bin/
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
else
    echo "Terraform already installed"
fi

terraform version

echo
echo "=== 5. Checking AWS credentials ==="

if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS credentials are working:"
    aws sts get-caller-identity
else
    echo
    echo "AWS credentials are NOT configured."
    echo "Run:"
    echo
    echo "aws configure"
    echo
    echo "Then enter:"
    echo "AWS Access Key ID"
    echo "AWS Secret Access Key"
    echo "Region: eu-west-1"
    echo "Output: json"
    echo
    exit 1
fi

echo
echo "=== 6. Moving to Terraform directory ==="

if [ -d "terraform" ]; then
    cd terraform
elif [ "$(basename "$PWD")" = "terraform" ]; then
    echo "Already inside terraform directory"
else
    echo "terraform directory not found"
    exit 1
fi

echo
echo "=== 7. Terraform initialization ==="

terraform init

echo
echo "=== 8. Formatting Terraform files ==="

terraform fmt

echo
echo "=== 9. Validating Terraform ==="

terraform validate

echo
echo "=== 10. Terraform plan ==="

terraform plan

echo
echo "========================================"
echo "Terraform environment is ready."
echo "Review the plan carefully."
echo
echo "If everything looks correct, run:"
echo
echo "terraform apply"
echo "========================================"