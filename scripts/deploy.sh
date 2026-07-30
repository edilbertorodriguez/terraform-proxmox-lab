#!/usr/bin/env bash

###############################################################################
# Terraform + Ansible Deployment Pipeline
#
# This script orchestrates the complete infrastructure deployment workflow.
#
# Workflow:
#   1. Validate Terraform configuration
#   2. Provision infrastructure in Proxmox
#   3. Verify the generated Ansible inventory
#   4. Validate the inventory
#   5. Bootstrap newly created Ubuntu servers with Ansible
#
###############################################################################

set -euo pipefail

###############################################################################
# Project Paths
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ANSIBLE_PROJECT="${HOME}/Projects/ansible-homelab"
INVENTORY="${PROJECT_ROOT}/generated/inventory.yml"

###############################################################################
# Banner
###############################################################################

echo
echo "=========================================================="
echo " Terraform + Ansible Deployment Pipeline"
echo "=========================================================="

###############################################################################
# Step 1 - Validate Terraform
###############################################################################

echo
echo "[1/5] Validating Terraform configuration..."

terraform fmt -check
terraform validate

###############################################################################
# Step 2 - Provision Infrastructure
###############################################################################

echo
echo "[2/5] Provisioning infrastructure..."

terraform apply -auto-approve

###############################################################################
# Step 3 - Verify Inventory
###############################################################################

echo
echo "[3/5] Verifying generated inventory..."

if [[ ! -f "${INVENTORY}" ]]; then
    echo
    echo "ERROR: Inventory file not found:"
    echo "  ${INVENTORY}"
    exit 1
fi

echo "Inventory located successfully."

###############################################################################
# Step 4 - Validate Inventory
###############################################################################

echo
echo "[4/5] Validating Ansible inventory..."

ansible-inventory \
    -i "${INVENTORY}" \
    --graph

###############################################################################
# Step 5 - Bootstrap Ubuntu Servers
###############################################################################

echo
echo "[5/5] Bootstrapping Ubuntu servers..."

pushd "${ANSIBLE_PROJECT}" >/dev/null

ansible-playbook \
    -i "${INVENTORY}" \
    playbooks/bootstrap-ubuntu.yml

popd >/dev/null

###############################################################################
# Finished
###############################################################################

echo
echo "=========================================================="
echo " Deployment completed successfully."
echo "=========================================================="
echo
