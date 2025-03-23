#!/bin/bash

set -e

# Parse input from stdin (this is how Terraform external provider passes data)
eval "$(jq -r '@sh "INSTANCE_SSH_PORT=\(.instance_ssh_port) INSTANCE_USER=\(.instance_username) INSTANCE_IP=\(.instance_ipv4)"')"

# Verify SSH connection and file exists before trying to fetch it
ssh -p "$INSTANCE_SSH_PORT" "$INSTANCE_USER@$INSTANCE_IP" "test -f /home/$INSTANCE_USER/.kube/config" || { echo '{"content":""}'; exit 1; }

# Get the kubeconfig content
KUBECONFIG=$(ssh -p "$INSTANCE_SSH_PORT" "$INSTANCE_USER@$INSTANCE_IP" "cat /home/$INSTANCE_USER/.kube/config" | base64 -w 0)

# Output the content in a format that Terraform can read
echo "{\"content\":\"$KUBECONFIG\"}"
