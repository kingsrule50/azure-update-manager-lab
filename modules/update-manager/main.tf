# Three distinct operations (same as the SOP):
#   1. Azure Policy      — auto-enrolls VMs into periodic patch ASSESSMENT
#   2. Maintenance Config — WHEN to patch, WHAT classifications, reboot behavior
#   3. Maintenance Assignments — link the schedule to each VM (enables PATCHING)
# Assessment and patching are separate. A VM needs both.

variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "resource_group_id" { type = string }

variable "vm_ids" {
  type        = map(string)
  description = "Map of VM name => VM resource ID"
}

# Azure Policy: built-in 59efceea = "Configure periodic checking for missing
# system updates on Azure VMs". Assessment only — it does not apply patches.
# Any new VM added to this resource group is automatically enrolled.
# NOTE (deviation from SOP): this policy has a Modify effect, so the
# assignment requires a managed identity and location.
resource "azurerm_resource_group_policy_assignment" "aum_assessment" {
  name                 = "aum-periodic-assessment"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15"
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

# Maintenance Configuration: weekly window, Critical/Security/UpdateRollup,
# reboot only if a patch requires it.
resource "azurerm_maintenance_configuration" "weekly" {
  name                     = "aum-weekly-patches"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  window {
    start_date_time = "2026-08-01 02:00" # Must be a future date at apply time
    time_zone       = "Eastern Standard Time"
    duration        = "03:00"
    recur_every     = "Week"
  }

  install_patches {
    windows {
      classifications_to_include = ["Critical", "Security", "UpdateRollup"]
    }
    reboot = "IfRequired"
  }
}

# Maintenance Assignments: one per VM. Without these, VMs are assessed
# (via policy) but never automatically patched.
resource "azurerm_maintenance_assignment_virtual_machine" "vm" {
  for_each = var.vm_ids

  location                     = var.location
  maintenance_configuration_id = azurerm_maintenance_configuration.weekly.id
  virtual_machine_id           = each.value
}
