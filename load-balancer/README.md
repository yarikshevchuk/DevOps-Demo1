# Load Balancer (Nginx)

This module configures Nginx as a reverse proxy and load balancer to distribute incoming traffic between application nodes (`app1.local` and `app2.local`)[cite: 10].

---

## 1. Node Network Parameters
According to the project's network specification (`VMnet2`)[cite: 10]:
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
```

The script automatically installs `nginx`, places the load balancer configuration, removes default virtual hosts, validates syntax, and restarts the service.

---

## 3. Host-Level VMware Port Forwarding
To allow external clients and the host machine to access the service via VMware NAT (`VMnet2`)[cite: 10]:

### Option A: Direct config file edit (Ubuntu Host)
On the VMware host machine, edit `/etc/vmware/vmnet2/nat/nat.conf` and append to `[incomingtcp]`[cite: 10]:
8080 = 192.168.50.10:80

Then restart the virtual network service[cite: 10]:
sudo systemctl restart vmware-networks

### Option B: VMware GUI
1. Open **Edit** -> **Virtual Network Editor...**
2. Select **VMnet2** -> click **NAT Settings...**[cite: 10]
3. In **Port Forwarding**, add:
   - **Host Port:** `8080`
   - **Type:** `TCP`
   - **Virtual Machine IP:** `192.168.50.10`[cite: 10]
   - **Virtual Machine Port:** `80`

The application will be accessible on the host at: `http://localhost:8080`.

---