#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# load config
. $SCRIPT_PATH/config.sh

# get instance details
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform apply -auto-approve
instance_ipv4=$(terraform output -raw instance_ipv4)
instance_username=$(terraform output -raw instance_username)
instance_ssh_port=$(terraform output -raw ssh_port)
cd ../../

# connect to instance
ssh -p $instance_ssh_port $instance_username@$instance_ipv4
