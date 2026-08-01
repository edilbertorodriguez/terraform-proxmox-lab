# Terraform Proxmox Infrastructure as Code

[![Terraform CI](https://github.com/edilbertorodriguez/terraform-proxmox-lab/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/edilbertorodriguez/terraform-proxmox-lab/actions/workflows/terraform-ci.yml)

> Infrastructure as Code project that provisions Ubuntu virtual machines on Proxmox VE, discovers their network addresses, validates the deployed systems, generates an Ansible inventory, and launches configuration management automatically.

---

## Project Overview

This project demonstrates a complete Infrastructure as Code workflow using Terraform, Proxmox VE, Cloud-Init, the QEMU Guest Agent, and Ansible.

Terraform defines and provisions the virtual machines. After deployment, an automated validation script confirms that the systems are operational before the generated inventory is passed to Ansible.

The project is designed to make infrastructure deployments:

* Repeatable
* Version controlled
* Modular
* Idempotent
* Automatically validated
* Ready for configuration management

---

## Current Capabilities

* Modular Terraform architecture
* Reusable Ubuntu VM module
* Multiple VM deployment using `for_each`
* Per-VM CPU, memory, disk, VM ID, and power configuration
* Full cloning from an Ubuntu 24.04 Cloud-Init template
* SSH public-key injection
* DHCP network configuration
* DNS and search-domain configuration
* Dynamic IPv4 discovery through the QEMU Guest Agent
* Automatic Ansible inventory generation
* Terraform-to-Ansible deployment orchestration
* Automated post-deployment infrastructure validation
* GitHub Actions continuous integration
* Terraform formatting and configuration checks
* TFLint static analysis
* Trivy infrastructure security scanning
* ShellCheck script analysis
* Git-based feature development and version tagging

---

## Technologies

| Technology              | Purpose                                              |
| ----------------------- | ---------------------------------------------------- |
| Terraform               | Infrastructure provisioning and lifecycle management |
| Proxmox VE 9            | Virtualization platform                              |
| BPG Proxmox Provider    | Terraform integration with Proxmox                   |
| Ubuntu Server 24.04 LTS | Controller and virtual-machine operating system      |
| Cloud-Init              | Initial guest configuration                          |
| QEMU Guest Agent        | Guest information and dynamic IP discovery           |
| Ansible                 | Post-provisioning configuration management           |
| Bash                    | Deployment and validation orchestration              |
| SSH                     | Secure remote administration and validation          |
| Git                     | Source control and release management                |
| GitHub Actions          | Continuous integration                               |
| TFLint                  | Terraform static analysis                            |
| Trivy                   | Infrastructure configuration security scanning       |
| ShellCheck              | Shell-script static analysis                         |

---

## Architecture

```text
                    +--------------------------+
                    |   Terraform Controller   |
                    |   Ubuntu Server 24.04    |
                    +------------+-------------+
                                 |
                         scripts/deploy.sh
                                 |
                                 v
                    +--------------------------+
                    | Terraform validation     |
                    | terraform apply          |
                    +------------+-------------+
                                 |
                                 v
                    +--------------------------+
                    |      Proxmox VE Host     |
                    |         pve-k9           |
                    +------------+-------------+
                                 |
               +-----------------+-----------------+
               |                                   |
               v                                   v
      +-------------------+               +-------------------+
      | ubuntu-test01     |               | ubuntu-test02     |
      | VM ID 500         |               | VM ID 501         |
      +---------+---------+               +---------+---------+
                |                                   |
                +-----------------+-----------------+
                                  |
                                  v
                   QEMU Guest Agent reports IPs
                                  |
                                  v
                 Terraform generates inventory.yml
                                  |
                                  v
                  Post-deployment validation runs
                                  |
                                  v
                     Ansible bootstrap executes
```

---

## Repository Structure

```text
terraform-proxmox-lab/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml
├── generated/
│   ├── .gitkeep
│   └── inventory.yml
├── modules/
│   └── ubuntu_vm/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── screenshots/
│   ├── architecture.png
│   ├── proxmox-dashboard.png
│   ├── ssh-ubuntu-test02.png
│   ├── terraform-apply.png
│   └── terraform-plan.png
├── scripts/
│   ├── deploy.sh
│   └── validate.sh
├── templates/
│   └── ansible_inventory.yml.tftpl
├── .gitignore
├── .terraform.lock.hcl
├── ansible_inventory.tf
├── LICENSE
├── main.tf
├── outputs.tf
├── providers.tf
├── README.md
├── variables.tf
└── versions.tf
```

Local Terraform state, backup state files, `.terraform/`, and sensitive variable files must not be committed to the repository.

---

## Terraform VM Module

The reusable `ubuntu_vm` module defines the lifecycle and configuration of an Ubuntu virtual machine.

Each module instance can configure:

* Proxmox node
* VM ID
* VM name
* CPU cores
* Dedicated memory
* Disk size
* Datastore
* Network bridge
* IPv4 configuration
* Default gateway
* DNS server
* Search domain
* Cloud-Init username
* SSH public keys
* Initial power state

Example module deployment:

```hcl
module "ubuntu_vms" {
  source   = "./modules/ubuntu_vm"
  for_each = local.ubuntu_vms

  node_name = "pve-k9"
  vm_id     = each.value.vm_id
  vm_name   = each.value.vm_name

  cpu_cores    = each.value.cpu_cores
  memory_mb    = each.value.memory_mb
  disk_size_gb = each.value.disk_size_gb
  ipv4_address = each.value.ipv4_address
  ipv4_gateway = each.value.ipv4_gateway
  started      = each.value.started

  ssh_public_keys = [
    "ssh-ed25519 YOUR_PUBLIC_KEY terraform-controller"
  ]
}
```

---

## Multiple VM Deployment

Virtual machines are defined in a local map and deployed with `for_each`.

```hcl
locals {
  ubuntu_vms = {
    ubuntu-test01 = {
      vm_id        = 500
      vm_name      = "ubuntu-test01"
      cpu_cores    = 2
      memory_mb    = 2048
      disk_size_gb = 20
      ipv4_address = "dhcp"
      ipv4_gateway = null
      started      = true
    }

    ubuntu-test02 = {
      vm_id        = 501
      vm_name      = "ubuntu-test02"
      cpu_cores    = 4
      memory_mb    = 4096
      disk_size_gb = 25
      ipv4_address = "dhcp"
      ipv4_gateway = null
      started      = true
    }
  }
}
```

This avoids duplicated resource definitions and makes additional virtual machines easier to add.

---

## Cloud-Init Provisioning

Each VM is cloned from an Ubuntu 24.04 Cloud-Init template.

Cloud-Init configures:

* Initial user account
* SSH authorized keys
* DHCP or static network settings
* Default gateway
* DNS server
* DNS search domain

The VMs can therefore be accessed securely without manually configuring local passwords.

---

## Dynamic IP Discovery

The QEMU Guest Agent reports the network addresses assigned inside each virtual machine.

Terraform filters the returned addresses and exposes the first valid non-loopback IPv4 address:

```hcl
output "primary_ipv4_address" {
  description = "First non-loopback IPv4 address reported by the QEMU guest agent"

  value = try(
    [
      for address in flatten(
        proxmox_virtual_environment_vm.this.ipv4_addresses
      ) :
      address
      if address != "127.0.0.1" &&
      can(cidrnetmask("${address}/32"))
    ][0],
    null
  )
}
```

This allows the workflow to support DHCP while still producing usable connection information.

---

## Automatic Ansible Inventory

Terraform generates `generated/inventory.yml` from the deployed VM outputs.

Example:

```yaml
---
all:
  children:
    ubuntu_servers:
      hosts:
        ubuntu-test01:
          ansible_host: 10.10.60.105
          ansible_user: ubuntu
        ubuntu-test02:
          ansible_host: 10.10.60.106
          ansible_user: ubuntu
      vars:
        ansible_connection: ssh
        ansible_python_interpreter: /usr/bin/python3
```

The addresses are generated dynamically and can change when DHCP leases change.

The deployment pipeline does not rely on manually maintained IP addresses.

---

## Post-Deployment Validation

The executable `scripts/validate.sh` script validates the deployed infrastructure before Ansible configuration begins.

It performs eight checks:

1. Confirms that Terraform state is accessible.
2. Reads the `virtual_machines` Terraform output.
3. Confirms that every VM has a discovered IPv4 address.
4. Tests ICMP network reachability.
5. Confirms that TCP port 22 is accepting connections.
6. Verifies authenticated SSH access with the Cloud-Init user.
7. Waits for Cloud-Init to report `status: done`.
8. Confirms that `qemu-guest-agent` is active.

Run the validation independently:

```bash
./scripts/validate.sh
```

A successful validation ends with:

```text
Post-deployment validation completed successfully.
```

The script stops immediately with a nonzero exit status when any required check fails.

---

## End-to-End Deployment Pipeline

The `scripts/deploy.sh` script orchestrates the complete workflow:

1. Validate the Terraform configuration.
2. Provision or reconcile infrastructure in Proxmox.
3. Run post-deployment infrastructure validation.
4. Verify that the generated Ansible inventory exists.
5. Validate the Ansible inventory.
6. Run the Ansible Ubuntu bootstrap playbook.

Run the complete pipeline:

```bash
./scripts/deploy.sh
```

The workflow is:

```text
Terraform validation
        |
        v
Terraform apply
        |
        v
Post-deployment validation
        |
        v
Generated Ansible inventory
        |
        v
Ansible inventory validation
        |
        v
Ansible bootstrap
```

Because the scripts use:

```bash
set -euo pipefail
```

the pipeline stops when a required command or validation stage fails.

---

## Standard Terraform Workflow

Terraform can also be operated independently:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Inspect the deployed VM output:

```bash
terraform output virtual_machines
```

Inspect the managed resources:

```bash
terraform state list
```

---

## Idempotency

Terraform compares the desired configuration with the current Proxmox environment.

When no infrastructure changes are required, Terraform reports:

```text
No changes. Your infrastructure matches the configuration.
```

Ansible tasks are also designed to avoid unnecessary configuration changes when the systems already match the desired state.

---

## Continuous Integration

GitHub Actions validates pushes and pull requests targeting the `main` branch.

The CI workflow performs:

* `terraform fmt -check`
* Terraform initialization without configuring the production backend
* `terraform validate`
* TFLint static analysis
* Trivy configuration scanning
* ShellCheck analysis
* Terraform provider caching

The workflow is defined in:

```text
.github/workflows/terraform-ci.yml
```

Continuous integration validates the repository configuration but does not deploy infrastructure into the private Proxmox environment.

---

## Screenshots

### Architecture

![Terraform and Proxmox Architecture](screenshots/architecture.png)

### Terraform Plan

![Terraform Plan](screenshots/terraform-plan.png)

### Terraform Apply

![Terraform Apply](screenshots/terraform-apply.png)

### Proxmox Virtual Machines

![Proxmox Virtual Machines](screenshots/proxmox-dashboard.png)

### SSH Validation

![SSH Validation](screenshots/ssh-ubuntu-test02.png)

---

## Version History

| Version | Description                                                                             |
| ------- | --------------------------------------------------------------------------------------- |
| v0.1.0  | Initial reusable Ubuntu VM module                                                       |
| v0.2.0  | Refactored VM deployment using `for_each`                                               |
| v0.3.0  | Added a second Ubuntu virtual machine                                                   |
| v0.4.0  | Added per-VM resources and power configuration                                          |
| v1.3.0  | Completed dynamic inventory generation and the Terraform-to-Ansible deployment pipeline |
| v1.4.0  | Adds automated post-deployment validation before Ansible execution                      |

Terraform v1.4.0 remains under development until the feature branch is reviewed, merged, and tagged.

---

## Current Status

The current development branch includes:

* Two Ubuntu 24.04 virtual machines managed by Terraform
* Reusable module-based VM definitions
* DHCP-based networking
* Dynamic QEMU Guest Agent IP discovery
* Generated Ansible inventory
* Automated Terraform-to-Ansible orchestration
* Eight-stage post-deployment validation
* Successful end-to-end deployment testing
* Zero failed and zero unreachable Ansible hosts during the latest pipeline test

---

## Planned Enhancements

Potential future improvements include:

* Static DHCP reservations or static IP assignment
* Remote Terraform state
* Encrypted secret management
* Multiple environments such as development, lab, and production
* Additional reusable Proxmox modules
* Deployment reporting
* Automated test result artifacts
* Wazuh and Security Onion infrastructure modules
* Separate Puppet integration and repository

Puppet is planned as a separate configuration-management project rather than being embedded directly into this Terraform repository.

---

## Learning Objectives

This project demonstrates practical experience with:

* Infrastructure as Code
* Declarative infrastructure
* Terraform modules
* Terraform state
* Resource iteration with `for_each`
* Cloud-Init
* Proxmox API automation
* QEMU Guest Agent integration
* Dynamic inventory generation
* Bash automation
* Infrastructure validation
* SSH administration
* Ansible integration
* Idempotent deployments
* Git branching and release workflows
* Continuous integration
* Infrastructure security scanning

---

## Author

**Edilberto Rodriguez**

Infrastructure Automation • Networking • Cybersecurity • Virtualization

Blue Team Level 1 (BTL1)

Building enterprise-style home lab environments focused on infrastructure automation, cybersecurity, systems engineering, and satellite communications.

---

## License

This project is intended for educational and portfolio purposes. See `LICENSE` for details.
