#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

. $SCRIPTPATH/config.sh

# Destroy the resources
cd terraform/$CLOUD_PROVIDER/
terraform init
terraform destroy -auto-approve
cd ../../
