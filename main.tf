module "ubuntu_test01" {
  source = "./modules/ubuntu_vm"

  node_name       = "pve-k9"
  vm_id           = 500
  vm_name         = "ubuntu-test01"
  ssh_public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOi7IZ9W8zkGwsb0C0hPMon61NhfvgT0ptMve++t83Eg terraform-controller"]
}
