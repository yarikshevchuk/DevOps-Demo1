# Load Balancer (Nginx)

This module configures Nginx as a reverse proxy and load balancer to distribute incoming traffic between application nodes (`app1.local` and `app2.local`).

---

## 1. Node Network Parameters
According to the project's network specification (`VMnet2`):
- **Hostname:** `lb.local`[cite: 10]
- **Internal IP:** `192.168.50.10`[cite: 10]
- **Subnet:** `192.168.50.0/24`[cite: 10]
- **Listening port:** `80` (HTTP)

---

## 2. Quick Deployment
On the Load Balancer node, navigate to the module directory and run the automatic installation script:

```bash
cd load-balancer
chmod +x setup_nginx.sh
./setup_nginx.sh