variable "node_name" {
  description = "Target Proxmox node"
  type        = string
}

variable "vm_id" {
  description = "Unique Proxmox VM ID"
  type        = number
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "template_vm_id" {
  description = "VM ID of the source template"
  type        = number
  default     = 9000
}

variable "datastore" {
  description = "Proxmox datastore for the VM disk"
  type        = string
  default     = "local-lvm"
}

variable "bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr1"
}

variable "cpu_cores" {
  description = "Number of virtual CPU cores"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Memory allocation in megabytes"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Primary disk size in gigabytes"
  type        = number
  default     = 20
}

variable "ci_username" {
  description = "Cloud-Init username"
  type        = string
  default     = "ubuntu"
}

variable "dns_server" {
  description = "DNS server"
  type        = string
  default     = "10.10.30.53"
}

variable "search_domain" {
  description = "DNS search domain"
  type        = string
  default     = "local"
}

variable "ipv4_address" {
  description = "IPv4 address or dhcp"
  type        = string
  default     = "dhcp"
}

variable "ipv4_gateway" {
  description = "Gateway (leave null for DHCP)"
  type        = string
  default     = null
}
variable "ssh_public_keys" {
  description = "SSH public keys for the Cloud-Init user"
  type        = list(string)
  default     = []
}
variable "started" {
  description = "Whether the virtual machine should be running"
  type        = bool
  default     = true
}
