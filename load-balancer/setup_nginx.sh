#!/usr/bin/env bash
set -e

echo "=== [1/4] Nginx installation ==="
sudo apt-get update -y
sudo apt-get install -y nginx

echo "=== [2/4] Copying Load Balancer configuration ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo cp "$SCRIPT_DIR/load_balancer.conf" /etc/nginx/conf.d/load_balancer.conf

if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi

echo "=== [3/4] Checking configuration ==="
sudo nginx -t

echo "=== [4/4] Starting and enabling service ==="
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "=== Nginx successfully deployed! ==="