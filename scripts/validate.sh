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
#   6. Confirm authenticated SSH access works
#   7. Confirm cloud-init completed successfully
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
echo "[1/7] Verifying Terraform state..."

terraform state list >/dev/null

echo "Terraform state is accessible."

echo
echo "[2/7] Reading deployed virtual machine information..."

VIRTUAL_MACHINES_JSON="$(terraform output -json virtual_machines)"

if [[ -z "${VIRTUAL_MACHINES_JSON}" || "${VIRTUAL_MACHINES_JSON}" == "{}" ]]; then
    echo "ERROR: No deployed virtual machines were found in Terraform output."
    exit 1
fi

echo "Virtual machine output loaded successfully."

echo
echo "[3/7] Validating discovered IPv4 addresses..."

mapfile -t VM_NAMES < <(
    jq -r 'keys[]' <<<"${VIRTUAL_MACHINES_JSON}"
)

declare -A VM_IPS
declare -A VM_USERS

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

    VM_USER="$(
        jq -r --arg name "${VM_NAME}"             '.[$name].ssh_username // empty'             <<<"${VIRTUAL_MACHINES_JSON}"
    )"

    if [[ -z "${VM_USER}" ]]; then
        echo "ERROR: ${VM_NAME} does not have an SSH username."
        exit 1
    fi

    VM_IPS["${VM_NAME}"]="${VM_IP}"
    VM_USERS["${VM_NAME}"]="${VM_USER}"

    echo "PASS: ${VM_NAME} reported IPv4 address ${VM_IP}"
done

echo
echo "[4/7] Validating network reachability..."

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
echo "[5/7] Validating SSH availability..."

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
echo "[6/7] Validating authenticated SSH access..."

KNOWN_HOSTS_FILE="$(mktemp)"
trap 'rm -f "${KNOWN_HOSTS_FILE}"' EXIT

for VM_NAME in "${VM_NAMES[@]}"; do
    VM_IP="${VM_IPS[${VM_NAME}]}"
    VM_USER="${VM_USERS[${VM_NAME}]}"

    echo "Authenticating to ${VM_NAME} as ${VM_USER}..."

    if ! ssh         -o BatchMode=yes         -o ConnectTimeout=5         -o StrictHostKeyChecking=accept-new         -o UserKnownHostsFile="${KNOWN_HOSTS_FILE}"         "${VM_USER}@${VM_IP}"         'true'; then
        echo "ERROR: Authenticated SSH failed for ${VM_USER}@${VM_IP}."
        exit 1
    fi

    echo "PASS: Authenticated SSH succeeded for ${VM_USER}@${VM_IP}"
done

echo
echo "[7/7] Validating cloud-init completion..."

for VM_NAME in "${VM_NAMES[@]}"; do
    VM_IP="${VM_IPS[${VM_NAME}]}"
    VM_USER="${VM_USERS[${VM_NAME}]}"

    echo "Checking cloud-init on ${VM_NAME}..."

    CLOUD_INIT_STATUS="$(
        ssh             -o BatchMode=yes             -o ConnectTimeout=5             -o StrictHostKeyChecking=accept-new             -o UserKnownHostsFile="${KNOWN_HOSTS_FILE}"             "${VM_USER}@${VM_IP}"             'cloud-init status --wait'
    )"

    if [[ "${CLOUD_INIT_STATUS}" != *"status: done"* ]]; then
        echo "ERROR: cloud-init did not complete successfully on ${VM_NAME}."
        echo "${CLOUD_INIT_STATUS}"
        exit 1
    fi

    echo "PASS: cloud-init completed successfully on ${VM_NAME}"
done

echo
echo "=========================================================="
echo " Post-deployment validation completed successfully."
echo "=========================================================="
echo
