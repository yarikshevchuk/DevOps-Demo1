#!/usr/bin/env bash
set -e

CURRENT_USER="$(whoami)"
USER_HOME="$(eval echo "~$CURRENT_USER")"

echo "=== [1/5] Java and Maven installation ==="
sudo apt-get update -y
sudo apt-get install -y openjdk-21-jdk maven

echo "=== [2/5] Check versions ==="
java -version
mvn -version

echo "=== [3/5] Preparing application configuration ==="
sudo mkdir -p /etc/cinema

if [ ! -f /etc/cinema/cinema.env ]; then
    sudo touch /etc/cinema/cinema.env
    sudo chmod 600 /etc/cinema/cinema.env
    echo "Created /etc/cinema/cinema.env"
else
    echo "/etc/cinema/cinema.env already exists"
fi

echo "=== [4/5] Installing systemd service ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sed \
    -e "s|__USER__|$CURRENT_USER|g" \
    -e "s|__HOME__|$USER_HOME|g" \
    "$SCRIPT_DIR/cinema.service" | sudo tee /etc/systemd/system/cinema.service > /dev/null

sudo systemctl daemon-reload

echo "=== [5/5] Starting and enabling application ==="
sudo systemctl enable cinema
sudo systemctl restart cinema

echo "=== Application successfully deployed! ==="
sudo systemctl status cinema --no-pager

echo "=== Application successfully deployed! ==="
sudo systemctl status cinema --no-pager
