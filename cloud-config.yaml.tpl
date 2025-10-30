#cloud-config
package_update: true

packages:
  - curl
  - ufw
  - unattended-upgrades
  - fail2ban
  - needrestart

write_files:
  - path: /etc/fail2ban/jail.d/sshd-local.conf
    owner: root:root
    permissions: "0644"
    content: |
      [sshd]
      enabled = true
      port = ssh
      filter = sshd
      maxretry = 5
      bantime = 1h
  - path: /etc/needrestart/conf.d/auto-restart.conf
    owner: root:root
    permissions: "0644"
    content: |
      # Automatically restart services after security updates
      $nrconf{restart} = 'a';

users:
  - name: user
    gecos: "User"
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: ${user_password_hash}
    ssh_authorized_keys:
      - ${ssh_authorized_key}

runcmd:
  # enable services
  - [ sh, -c, "systemctl enable --now unattended-upgrades" ]
  - [ sh, -c, "systemctl enable --now fail2ban" ]

  # install k3s
  - [ sh, -c, "curl -sfL https://get.k3s.io -o /usr/local/bin/install-k3s.sh" ]
  - [ sh, -c, "chmod +x /usr/local/bin/install-k3s.sh" ]
  - [ sh, -c, "INSTALL_K3S_EXEC='server --disable=traefik --disable=metrics-server --write-kubeconfig-mode 644' K3S_KUBECONFIG_MODE=644 /usr/local/bin/install-k3s.sh" ]
  - [ sh, -c, "until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 2; done" ]
  - [ sh, -c, "install -m 600 -o user -g user /etc/rancher/k3s/k3s.yaml /home/user/k3s.yaml" ]

  # configure firewall
  - [ sh, -c, "ufw default deny incoming" ]
  - [ sh, -c, "ufw default allow outgoing" ]
  - [ sh, -c, "ufw allow OpenSSH" ]
%{ for cidr in allowed_api_cidrs ~}
  - [ sh, -c, "ufw allow from ${cidr} to any port 6443 proto tcp" ]
%{ endfor ~}
  - [ sh, -c, "ufw --force enable" ]
