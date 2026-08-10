#!/bin/bash

URL="http://localhost:8080"

echo "Checking application..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS" -eq 200 ]; then
    echo "Application is healthy"
    exit 0
else
    echo "Application health check failed: HTTP $STATUS"
    exit 1
fi