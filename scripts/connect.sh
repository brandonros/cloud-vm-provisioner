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
cd ../../

# connect to instance
ssh $instance_username@$instance_ipv4
