#!/bin/bash

set -euxo pipefail

JENKINS_HOME="/var/lib/jenkins"
REPO_DIR="/opt/practical-task"

# --------------------------------------------------
# 1. Prepare Amazon Linux
# --------------------------------------------------

dnf clean all
rm -rf /var/cache/dnf
dnf makecache -y

dnf install -y \
  git \
  curl \
  wget \
  jq \
  unzip \
  java-21-amazon-corretto \
  docker \
  awscli

# --------------------------------------------------
# 2. Docker
# --------------------------------------------------

systemctl enable docker
systemctl start docker

# --------------------------------------------------
# 3. Clone project
# --------------------------------------------------

rm -rf "$REPO_DIR"

git clone \
  --branch terraform-automation \
  https://github.com/paradisecreate/Practical-task-.git \
  "$REPO_DIR"

# --------------------------------------------------
# 4. Jenkins repository
# --------------------------------------------------

wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/rpm-stable/jenkins.repo

rpm --import \
  https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

dnf clean all
dnf makecache -y

dnf install -y jenkins

# --------------------------------------------------
# 5. Jenkins permissions
# --------------------------------------------------

usermod -aG docker jenkins

mkdir -p "$JENKINS_HOME/plugins"
mkdir -p "$JENKINS_HOME/casc"

# --------------------------------------------------
# 6. Install Jenkins plugins
# --------------------------------------------------

PLUGIN_MANAGER_URL=$(
  curl -fsSL \
    https://api.github.com/repos/jenkinsci/plugin-installation-manager-tool/releases/latest \
  | jq -r \
    '.assets[] | select(.name | endswith(".jar")) | .browser_download_url' \
  | head -n 1
)

curl -fsSL \
  "$PLUGIN_MANAGER_URL" \
  -o /tmp/jenkins-plugin-manager.jar

java -jar /tmp/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-download-directory "$JENKINS_HOME/plugins" \
  --plugins \
    configuration-as-code \
    job-dsl \
    workflow-aggregator \
    git

# --------------------------------------------------
# 7. Jenkins Configuration as Code
# --------------------------------------------------

cp "$REPO_DIR/jenkins/jenkins.yaml" \
   "$JENKINS_HOME/casc/jenkins.yaml"

cp "$REPO_DIR/jenkins/jobs.groovy" \
   "$JENKINS_HOME/casc/jobs.groovy"

chown -R jenkins:jenkins "$JENKINS_HOME"

# --------------------------------------------------
# 8. Configure Jenkins service
# --------------------------------------------------

mkdir -p /etc/systemd/system/jenkins.service.d

cat > /etc/systemd/system/jenkins.service.d/override.conf <<'EOF'
[Service]
Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/casc/jenkins.yaml"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
EOF

systemctl daemon-reload

# --------------------------------------------------
# 9. Start Jenkins
# --------------------------------------------------

systemctl enable jenkins
systemctl restart jenkins

# --------------------------------------------------
# 10. Wait for Jenkins
# --------------------------------------------------

for i in {1..60}; do
    if curl -s http://localhost:8080/login >/dev/null; then
        echo "Jenkins is ready"
        break
    fi

    echo "Waiting for Jenkins..."
    sleep 5
done

# --------------------------------------------------
# 11. Final checks
# --------------------------------------------------

systemctl is-active --quiet docker
systemctl is-active --quiet jenkins

aws sts get-caller-identity

echo "Bootstrap completed successfully"