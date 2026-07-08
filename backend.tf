terraform {
  backend "azurerm" {
    resource_group_name  = "RG-TerraformState"
    storage_account_name = "tfstatechinedu2025"
    container_name       = "tfstate"
    key                  = "aum-lab.tfstate"
    # Separate from the ntfs-lab and rbac-lab state files.
    # All labs share the same container without affecting each other.
  }
}
