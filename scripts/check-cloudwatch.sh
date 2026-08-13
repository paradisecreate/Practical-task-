#!/bin/bash
set -euo pipefail

REGION="${AWS_REGION:-eu-west-1}"

echo "Checking CloudWatch Agent service..."

if systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "CloudWatch Agent is running."
else
    echo "CloudWatch Agent is NOT running."
    exit 1
fi

echo "Getting current EC2 instance ID..."

TOKEN=$(curl -sS -X PUT \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60" \
    http://169.254.169.254/latest/api/token)

INSTANCE_ID=$(curl -sS \
    -H "X-aws-ec2-metadata-token: ${TOKEN}" \
    http://169.254.169.254/latest/meta-data/instance-id)

echo "Instance: ${INSTANCE_ID}"

echo "Checking mem_used_percent in CloudWatch..."

COUNT=$(aws cloudwatch list-metrics \
    --namespace Team2/EC2 \
    --metric-name mem_used_percent \
    --dimensions Name=InstanceId,Value="${INSTANCE_ID}" \
    --region "${REGION}" \
    --query 'length(Metrics)' \
    --output text)

if [ "${COUNT}" -gt 0 ]; then
    echo "CloudWatch memory metric exists."
else
    echo "CloudWatch memory metric was not found."
    exit 1
fi