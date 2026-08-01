#!/usr/bin/env bash

###############################################################################
# Terraform Post-Deployment Validation
#
# Validates infrastructure after Terraform provisioning and before Ansible
# configuration begins.
#
# Validation stages:
#   1. Confirm Terraform state is accessible
#   2. Read deployed VM connection information
#   3. Confirm each VM has a discovered IPv4 address
#   4. Confirm each VM is reachable over the network
#   5. Confirm each VM is accepting SSH connections
#
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

echo
echo "=========================================================="
echo " Terraform Post-Deployment Validation"
echo "=========================================================="

echo
echo "[1/5] Verifying Terraform state..."

terraform state list >/dev/null

echo "Terraform state is accessible."

echo
echo "[2/5] Reading deployed virtual machine information..."

VIRTUAL_MACHINES_JSON="$(terraform output -json virtual_machines)"

if [[ -z "${VIRTUAL_MACHINES_JSON}" || "${VIRTUAL_MACHINES_JSON}" == "{}" ]]; then
    echo "ERROR: No deployed virtual machines were found in Terraform output."
    exit 1
fi

echo "Virtual machine output loaded successfully."

echo
echo "[3/5] Validating discovered IPv4 addresses..."

mapfile -t VM_NAMES < <(
    jq -r 'keys[]' <<<"${VIRTUAL_MACHINES_JSON}"
)

declare -A VM_IPS

for VM_NAME in "${VM_NAMES[@]}"; do
    VM_IP="$(
        jq -r --arg name "${VM_NAME}" \
            '.[$name].primary_ipv4_address // empty' \
            <<<"${VIRTUAL_MACHINES_JSON}"
    )"

    if [[ -z "${VM_IP}" ]]; then
        echo "ERROR: ${VM_NAME} does not have a primary IPv4 address."
        exit 1
    fi

    VM_IPS["${VM_NAME}"]="${VM_IP}"

    echo "PASS: ${VM_NAME} reported IPv4 address ${VM_IP}"
done

echo
echo "[4/5] Validating network reachability..."

for VM_NAME in "${VM_NAMES[@]}"; do
    VM_IP="${VM_IPS[${VM_NAME}]}"

    echo "Checking ${VM_NAME} at ${VM_IP}..."

    if ! ping -c 1 -W 3 "${VM_IP}" >/dev/null 2>&1; then
        echo "ERROR: ${VM_NAME} at ${VM_IP} is not reachable by ICMP."
        exit 1
    fi

    echo "PASS: ${VM_NAME} is reachable at ${VM_IP}"
done

echo
echo "[5/5] Validating SSH availability..."

for VM_NAME in "${VM_NAMES[@]}"; do
    VM_IP="${VM_IPS[${VM_NAME}]}"

    echo "Checking SSH on ${VM_NAME} at ${VM_IP}:22..."

    if ! nc -z -w 3 "${VM_IP}" 22; then
        echo "ERROR: ${VM_NAME} is not accepting connections on TCP port 22."
        exit 1
    fi

    echo "PASS: ${VM_NAME} is accepting SSH connections."
done

echo
echo "=========================================================="
echo " Post-deployment validation completed successfully."
echo "=========================================================="
echo
