variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token in user@realm!token=secret format"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow an untrusted or self-signed Proxmox TLS certificate"
  type        = bool
  default     = true
}
