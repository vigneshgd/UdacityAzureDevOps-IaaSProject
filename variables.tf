variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "East US"
}

variable "username" {
  description = "User name for the VM being created"
}

variable "LbBeAddrPoolAssociationIp" {
  description = "IP address for Load balancer Back End Addr pool association"
}

variable "numvms" {
  description = "Number of VMs to be created"
}