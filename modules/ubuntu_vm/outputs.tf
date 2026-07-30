output "vm_name" {
  description = "Configured virtual machine name"
  value       = var.vm_name
}

output "vm_id" {
  description = "Virtual machine ID"
  value       = var.vm_id
}

output "node_name" {
  description = "Proxmox node hosting the VM"
  value       = var.node_name
}

output "cpu_cores" {
  description = "Allocated CPU cores"
  value       = var.cpu_cores
}

output "memory_mb" {
  description = "Allocated memory in MB"
  value       = var.memory_mb
}

output "ipv4_addresses" {
  description = "IPv4 addresses reported by the QEMU guest agent"
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}

output "ssh_username" {
  description = "Cloud-Init user used for SSH access"
  value       = var.ci_username
}

output "started" {
  description = "Whether the virtual machine is configured to be running"
  value       = var.started
}

output "primary_ipv4_address" {
  description = "First non-loopback IPv4 address reported by the QEMU guest agent"

  value = try(
    [
      for address in flatten(proxmox_virtual_environment_vm.this.ipv4_addresses) :
      address
      if address != "127.0.0.1" && can(cidrnetmask("${address}/32"))
    ][0],
    null
  )
}
