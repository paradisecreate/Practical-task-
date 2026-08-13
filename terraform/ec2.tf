#!/bin/bash

set -Eeuo pipefail

# --------------------------------------------------
# Logging
# --------------------------------------------------

exec > >(tee -a /var/log/practical-task-bootstrap.log \
  | logger -t practical-task-user-data -s 2>/dev/console) 2>&1

trap 'echo "BOOTSTRAP FAILED at line ${LINENO}: ${BASH_COMMAND}"' ERR

echo "======================================"
echo "Starting Practical Task bootstrap"
echo "======================================"

JENKINS_HOME="/var/lib/jenkins"
REPO_DIR="/opt/practical-task"

# --------------------------------------------------
# Helper: retry DNF commands
# --------------------------------------------------

dnf_retry() {
  for attempt in 1 2 3; do
    echo "DNF attempt ${attempt}: $*"

    if dnf -y "$@"; then
      return 0
    fi

    echo "DNF attempt ${attempt} failed"
    dnf clean all || true
    sleep 10
  done

  echo "DNF failed after 3 attempts"
  return 1
}

# --------------------------------------------------
# Amazon Linux packages
# --------------------------------------------------

dnf clean all
dnf -y makecache

dnf_retry install \
  git \
  curl \
  wget \
  fontconfig \
  java-21-amazon-corretto \
  docker

echo "Java:"
java -version

echo "AWS CLI:"
aws --version

# --------------------------------------------------
# Docker
# --------------------------------------------------

systemctl enable docker
systemctl start docker

docker --version

# --------------------------------------------------
# Jenkins repository
# --------------------------------------------------

curl --retry 5 --retry-delay 5 -fsSL \
  https://pkg.jenkins.io/rpm-stable/jenkins.repo \
  -o /etc/yum.repos.d/jenkins.repo

rpm --import \
  https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

dnf clean all
dnf -y makecache

dnf_retry install jenkins

# --------------------------------------------------
# Jenkins + Docker permission
# --------------------------------------------------

usermod -aG docker jenkins

# --------------------------------------------------
# Download repository containing JCasC / Job DSL
# --------------------------------------------------

rm -rf "$REPO_DIR"

for attempt in 1 2 3; do
  if git clone \
      --depth 1 \
      --branch terraform-automation \
      https://github.com/paradisecreate/Practical-task-.git \
      "$REPO_DIR"; then

    break
  fi

  echo "Git clone attempt ${attempt} failed"
  rm -rf "$REPO_DIR"
  sleep 10
done

test -f "$REPO_DIR/jenkins/jenkins.yaml"
test -f "$REPO_DIR/jenkins/jobs.groovy"

# --------------------------------------------------
# Jenkins directories
# --------------------------------------------------

mkdir -p "$JENKINS_HOME/plugins"
mkdir -p "$JENKINS_HOME/casc"

# --------------------------------------------------
# Jenkins Plugin Installation Manager
# --------------------------------------------------

PLUGIN_MANAGER_VERSION="2.15.0"

curl --retry 5 --retry-delay 5 -fsSL \
  "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${PLUGIN_MANAGER_VERSION}/jenkins-plugin-manager-${PLUGIN_MANAGER_VERSION}.jar" \
  -o /tmp/jenkins-plugin-manager.jar

java -jar /tmp/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-download-directory "$JENKINS_HOME/plugins" \
  --plugins \
    configuration-as-code \
    job-dsl \
    git \
    workflow-aggregator \
    pipeline-model-definition

# --------------------------------------------------
# Jenkins Configuration as Code
# --------------------------------------------------

cp "$REPO_DIR/jenkins/jenkins.yaml" \
  "$JENKINS_HOME/casc/jenkins.yaml"

cp "$REPO_DIR/jenkins/jobs.groovy" \
  "$JENKINS_HOME/casc/jobs.groovy"

chown -R jenkins:jenkins "$JENKINS_HOME"

# --------------------------------------------------
# Jenkins systemd configuration
# --------------------------------------------------

mkdir -p /etc/systemd/system/jenkins.service.d

cat > /etc/systemd/system/jenkins.service.d/override.conf <<'EOF'
[Service]
Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/casc/jenkins.yaml"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
EOF

chmod 0644 /etc/systemd/system/jenkins.service.d/override.conf

systemctl daemon-reload

# --------------------------------------------------
# Start Jenkins
# --------------------------------------------------

systemctl enable jenkins
systemctl restart jenkins

# --------------------------------------------------
# Wait for Jenkins
# --------------------------------------------------

echo "Waiting for Jenkins..."

JENKINS_READY=false

for attempt in $(seq 1 60); do
  if curl -sS --max-time 3 \
      http://localhost:8080/ \
      >/dev/null 2>&1; then

    JENKINS_READY=true
    echo "Jenkins is responding"
    break
  fi

  echo "Waiting for Jenkins... ${attempt}/60"
  sleep 5
done

if [ "$JENKINS_READY" != "true" ]; then
  echo "Jenkins did not become ready"
  journalctl -u jenkins --no-pager -n 200
  exit 1
fi

# --------------------------------------------------
# Verify pipeline job exists
# --------------------------------------------------

echo "Waiting for practical-task-pipeline..."

JOB_READY=false

for attempt in $(seq 1 30); do
  if curl -sS \
      http://localhost:8080/api/json \
      | grep -q '"practical-task-pipeline"'; then

    JOB_READY=true
    echo "Pipeline job exists"
    break
  fi

  sleep 2
done

if [ "$JOB_READY" != "true" ]; then
  echo "Pipeline job was not created"
  journalctl -u jenkins --no-pager -n 200
  exit 1
fi

# --------------------------------------------------
# Start initial pipeline automatically
# --------------------------------------------------

echo "Starting initial pipeline build..."

CRUMB=$(
  curl -sS \
    'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' \
    || true
)

if [ -n "$CRUMB" ]; then
  curl -sS -X POST \
    -H "$CRUMB" \
    http://localhost:8080/job/practical-task-pipeline/build \
    || true
else
  curl -sS -X POST \
    http://localhost:8080/job/practical-task-pipeline/build \
    || true
fi

# --------------------------------------------------
# Final validation
# --------------------------------------------------

systemctl is-active --quiet docker
systemctl is-active --quiet jenkins

aws sts get-caller-identity

echo "======================================"
echo "BOOTSTRAP COMPLETED SUCCESSFULLY"
echo "======================================"