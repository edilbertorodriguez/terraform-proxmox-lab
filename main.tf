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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOi7IZ9W8zkGwsb0C0hPMon61NhfvgT0ptMve++t83Eg terraform-controller"
  ]
}

moved {
  from = module.ubuntu_test01
  to   = module.ubuntu_vms["ubuntu-test01"]
}
