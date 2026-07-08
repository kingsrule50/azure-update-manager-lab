# Root module — reads existing Lab 1 infrastructure (no changes to it),
# then wires the update-manager module onto those VMs.
# Lab 1's own Terraform state is untouched: data sources are read-only.

data "azurerm_resource_group" "lab" {
  name = var.resource_group_name
}

data "azurerm_virtual_machine" "vm" {
  for_each            = toset(var.vm_names)
  name                = each.value
  resource_group_name = data.azurerm_resource_group.lab.name
}

module "update_manager" {
  source = "./modules/update-manager"

  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name
  resource_group_id   = data.azurerm_resource_group.lab.id
  vm_ids              = { for name, vm in data.azurerm_virtual_machine.vm : name => vm.id }
}
