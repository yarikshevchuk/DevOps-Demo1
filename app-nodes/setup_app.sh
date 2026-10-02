#!/usr/bin/env bash
set -e

APP_USER="${SUDO_USER:-$USER}"
APP_HOME="$(getent passwd "$APP_USER" | cut -d: -f6)"

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
    -e "s|__USER__|$APP_USER|g" \
    -e "s|__HOME__|$APP_HOME|g" \
    "$SCRIPT_DIR/cinema.service" | sudo tee /etc/systemd/system/cinema.service > /dev/null

sudo systemctl daemon-reload

echo "=== [5/5] Starting and enabling application ==="
sudo systemctl enable cinema
sudo systemctl restart cinema

echo "=== Application successfully deployed! ==="
sudo systemctl status cinema --no-pager
