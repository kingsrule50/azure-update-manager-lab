output "maintenance_configuration_id" {
  value = module.update_manager.maintenance_configuration_id
}

output "policy_assignment_id" {
  value = module.update_manager.policy_assignment_id
}

output "enrolled_vms" {
  value = var.vm_names
}
