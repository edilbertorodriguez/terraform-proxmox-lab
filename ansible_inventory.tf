resource "local_file" "ansible_inventory" {
  filename = "${path.module}/generated/inventory.yml"

  content = templatefile(
    "${path.module}/templates/ansible_inventory.yml.tftpl",
    {
      virtual_machines = module.ubuntu_vms
    }
  )

  file_permission = "0644"
}
