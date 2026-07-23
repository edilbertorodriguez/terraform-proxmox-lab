output "virtual_machines" {
  description = "Configuration summary for all deployed virtual machines"

  value = {
    for name, vm in module.ubuntu_vms : name => {
      vm_name   = vm.vm_name
      vm_id     = vm.vm_id
      node_name = vm.node_name
      cpu_cores = vm.cpu_cores
      memory_mb = vm.memory_mb
    }
  }
}
