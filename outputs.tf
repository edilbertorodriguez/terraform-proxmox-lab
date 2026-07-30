output "virtual_machines" {
  description = "Configuration and connection summary for all deployed virtual machines"

  value = {
    for name, vm in module.ubuntu_vms : name => {
      vm_name              = vm.vm_name
      vm_id                = vm.vm_id
      node_name            = vm.node_name
      cpu_cores            = vm.cpu_cores
      memory_mb            = vm.memory_mb
      ipv4_addresses       = vm.ipv4_addresses
      primary_ipv4_address = vm.primary_ipv4_address
      ssh_username         = vm.ssh_username
      started              = vm.started
    }
  }
}
