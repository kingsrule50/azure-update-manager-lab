# Adapted from the AUM Lab SOP: instead of deploying new VMs (rg-aumlab),
# we target the existing Lab 1 VMs in RG-FileServerLab via data sources.

variable "resource_group_name" {
  type    = string
  default = "RG-FileServerLab"
}

variable "vm_names" {
  type        = list(string)
  default     = ["DC01", "FS01"]
  description = "Existing Lab 1 VMs to enroll in Update Manager"
}
