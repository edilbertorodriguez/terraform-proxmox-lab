resource "proxmox_virtual_environment_vm" "this" {
  node_name = var.node_name
  vm_id     = var.vm_id
  name      = var.vm_name

  on_boot       = false
  scsi_hardware = "virtio-scsi-single"
  clone {
    vm_id        = var.template_vm_id
    datastore_id = var.datastore
    full         = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.datastore
    interface    = "scsi0"
    size         = var.disk_size_gb
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = var.datastore

    user_account {
      username = var.ci_username
      keys     = var.ssh_public_keys
    }

    dns {
      servers = [var.dns_server]
      domain  = var.search_domain
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }
  }

  operating_system {
    type = "l26"
  }

  started = var.started
}
