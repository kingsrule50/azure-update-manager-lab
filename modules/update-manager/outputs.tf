output "maintenance_configuration_id" {
  value = azurerm_maintenance_configuration.weekly.id
}

output "policy_assignment_id" {
  value = azurerm_resource_group_policy_assignment.aum_assessment.id
}
