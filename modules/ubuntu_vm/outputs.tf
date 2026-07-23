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
