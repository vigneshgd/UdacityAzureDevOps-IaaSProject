variable "prefix" {
  description = "The prefix which should be used for all resources in this example, eg DevOps"
  default = "DevOps"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "East US"
}

variable "username" {
  description = "User name for the VM being created"
  type        = string
  default = "vg2381"
}
