# Jenkins VM — Setup Guide

How to set up the team's Jenkins VM with `jenkins-vm-setup.sh`, and what has to be configured by hand afterwards.

| Item          | Value                         |
| ------------- | ----------------------------- |
| IP address    | `192.168.50.15`             |
| Hostname      | `jenkins`                   |
| Gateway / DNS | `192.168.50.2`              |
| Jenkins UI    | `http://192.168.50.15:8080` |

GitHub webhooks reach Jenkins through a smee.io relay, so Jenkins doesn't need to be reachable from outside the host.

---

## Before running the script

1. On the host, `VMnet2` is a **NAT** network: subnet `192.168.50.0/24`, DHCP off, gateway `192.168.50.2`.
2. Create the VM:

   - Ubuntu Server 24.04
   - 2 vCPU, 8 GB RAM, 40 GB disk
   - network adapter set to **Custom → vmnet2**
3. In the Ubuntu installer:

   - server name: `jenkins`
   - IP `192.168.50.15/24`, gateway `192.168.50.2`, DNS `192.168.50.2`
   - select **Install OpenSSH server**
4. After the first boot, log in on the VM console and check the network:

   ```bash
   ip route
   ```

   It must show `default via 192.168.50.2`. If it shows `.1`, or no default route, type in this configuration by hand:

   ```bash
   sudo rm -f /etc/netplan/50-cloud-init.yaml
   sudo nano /etc/netplan/01-netcfg.yaml
   ```

   ```yaml
   network:
     version: 2
     ethernets:
       ens33:
         dhcp4: no
         addresses: [192.168.50.15/24]
         routes:
           - to: default
             via: 192.168.50.2
         nameservers:
           addresses: [192.168.50.2]
   ```

   ```bash
   sudo chmod 600 /etc/netplan/01-netcfg.yaml
   sudo netplan apply
   ip route
   ```

   Check the interface name with `ip -br a` if it isn't `ens33`.
5. From the host, connect with `ssh <user>@192.168.50.15`. The remaining steps can be pasted over SSH.
6. Add the team's `/etc/hosts` entries. The script uses `app1.local` and `app2.local`.

   ```bash
   sudo tee -a /etc/hosts > /dev/null <<'EOF'
   192.168.50.10  lb.local lb
   192.168.50.11  app1.local app1
   192.168.50.12  app2.local app2
   192.168.50.15  ci.local jenkins.local jenkins
   192.168.50.20  db-master.local db-master
   192.168.50.21  db-slave.local db-slave
   EOF
   ```
7. Create a smee channel at `https://smee.io/new` and copy its URL. Don't commit this URL to the repository.

## Running the script

From the host:

```bash
scp jenkins-vm-setup.sh <user>@192.168.50.15:~
ssh <user>@192.168.50.15
sudo SMEE_URL=https://smee.io/<private_channel> bash jenkins-vm-setup.sh
```

The script:

1. Installs Java 21 and Maven.
2. Installs Jenkins.
3. Enables the firewall: SSH, and port 8080 from the internal network only.
4. Installs the smee relay as the `smee-jenkins` service.
5. Creates Jenkins' SSH keys for GitHub and the App VMs.
6. Prints the public keys needed in the steps below.

---

## Manual steps

### 1. Jenkins setup wizard

1. Open `http://192.168.50.15:8080` on the host.
2. Get the unlock key with `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`.
3. Choose **Install suggested plugins**, then add the **GitHub** plugin.
4. Create the admin user.

### 2. GitHub repository access

1. In the GitHub repo, go to **Settings → Deploy keys** and add the GitHub key printed by the script.
2. In Jenkins, go to **Manage Jenkins → Credentials** and add an **SSH Username with private key** credential:
   - ID: `github-deploy-key`
   - Username: `git`
   - Private key: the contents of `/var/lib/jenkins/.ssh/github_deploy`

### 3. GitHub webhook

1. Generate a secret with `openssl rand -hex 32`.
2. In GitHub, go to **Settings → Webhooks → Add webhook**:
   - Payload URL: the smee URL
   - Content type: `application/json`
   - Secret: the generated value
3. In Jenkins:
   - Add the same secret as a **Secret text** credential.
   - Select it under **Manage Jenkins → System → GitHub → Advanced → Shared secrets**.

### 4. Pipeline job

1. Create a **Pipeline** job.
2. Tick **GitHub hook trigger for GITScm polling**.
3. Use the repo URL `git@github.com:<org>/<repo>.git` with the `github-deploy-key` credential.
4. Run the job once by hand. After that, pushes start it automatically.

### 5. App VMs

Add the App VM key printed by the script to `~/.ssh/authorized_keys` of the deploy user on `app1` and `app2`.

---

## Checking the setup

| Check                                     | Expected result               |
| ----------------------------------------- | ----------------------------- |
| `ip route` on the VM                    | `default via 192.168.50.2`  |
| `systemctl status jenkins smee-jenkins` | both`active (running)`      |
| Push a commit to the repo                 | a new build starts in Jenkins |

If the VM can reach the host but not the internet, the gateway is set to `.1` instead of `.2`.
