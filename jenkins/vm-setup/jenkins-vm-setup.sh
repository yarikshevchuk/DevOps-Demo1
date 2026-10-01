#!/usr/bin/env bash
# Jenkins VM setup. Run on the Jenkins VM:
#   sudo SMEE_URL=https://smee.io/<channel> bash jenkins-vm-setup.sh
set -e

echo "=== [1/6] Installing Java and Maven ==="
apt-get update
apt-get upgrade -y
apt-get install -y fontconfig openjdk-21-jdk-headless maven

echo
echo "=== [2/6] Installing Jenkins ==="
wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y jenkins
systemctl enable --now jenkins

echo
echo "=== [3/6] Configuring firewall ==="
ufw allow OpenSSH
ufw allow from 192.168.50.0/24 to any port 8080 proto tcp
ufw --force enable

echo
echo "=== [4/6] Installing smee webhook relay ==="
# smee-client needs Node 20.18+ or 22; Ubuntu's own Node is too old
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install -g smee-client@4

echo "SMEE_URL=$SMEE_URL" > /etc/default/smee-jenkins
chmod 600 /etc/default/smee-jenkins

cat > /etc/systemd/system/smee-jenkins.service <<EOF
[Unit]
Description=smee.io webhook relay for Jenkins
After=network-online.target jenkins.service

[Service]
User=jenkins
EnvironmentFile=/etc/default/smee-jenkins
ExecStart=/usr/bin/smee -u \${SMEE_URL} -t http://127.0.0.1:8080/github-webhook/
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now smee-jenkins

echo
echo "=== [5/6] Creating SSH keys for Jenkins ==="
sudo -u jenkins mkdir -p -m 700 /var/lib/jenkins/.ssh
[ -f /var/lib/jenkins/.ssh/github_deploy ] || sudo -u jenkins ssh-keygen -t ed25519 -f /var/lib/jenkins/.ssh/github_deploy -N ""
[ -f /var/lib/jenkins/.ssh/id_ed25519 ] || sudo -u jenkins ssh-keygen -t ed25519 -f /var/lib/jenkins/.ssh/id_ed25519 -N ""
ssh-keyscan github.com app1.local app2.local | sudo -u jenkins tee -a /var/lib/jenkins/.ssh/known_hosts > /dev/null || true

echo
echo "=== [6/6] Done ==="
echo "Jenkins UI:  http://192.168.50.15:8080"
echo "Unlock key:  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo
echo "GitHub deploy key (add to the repo's Deploy keys):"
cat /var/lib/jenkins/.ssh/github_deploy.pub
echo
echo "App VM key (add to ~/.ssh/authorized_keys on app1 and app2):"
cat /var/lib/jenkins/.ssh/id_ed25519.pub