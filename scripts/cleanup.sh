#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# load config
. $SCRIPT_PATH/config.sh

# Destroy the resources
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform destroy -auto-approve
cd ../../
