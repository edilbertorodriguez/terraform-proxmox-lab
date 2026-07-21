locals {
  ubuntu_vms = {
    ubuntu-test01 = {
      vm_id   = 500
      vm_name = "ubuntu-test01"
    }
  }
}

module "ubuntu_vms" {
  source   = "./modules/ubuntu_vm"
  for_each = local.ubuntu_vms

  node_name = "pve-k9"
  vm_id     = each.value.vm_id
  vm_name   = each.value.vm_name

  ssh_public_keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOi7IZ9W8zkGwsb0C0hPMon61NhfvgT0ptMve++t83Eg terraform-controller"
  ]
}

moved {
  from = module.ubuntu_test01
  to   = module.ubuntu_vms["ubuntu-test01"]
}
