#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# load config
. $SCRIPTPATH/config.sh

# get instance details
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform apply -auto-approve
instance_ipv4=$(terraform output -raw instance_ipv4)
instance_username=$(terraform output -raw instance_username)
cd ../../

# copy scripts to instance
scp $SCRIPTPATH/benchmark.sh $instance_username@$instance_ipv4:~/benchmark.sh
scp $SCRIPTPATH/install-k3s.sh $instance_username@$instance_ipv4:~/install-k3s.sh
scp $SCRIPTPATH/install-krew.sh $instance_username@$instance_ipv4:~/install-krew.sh

# connect to instance
ssh $instance_username@$instance_ipv4