variable "prefix" {
  description = "The prefix which should be used for all resources in this example, eg DevOps"
  default = "devops"
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

variable "LbBkEndPoolAddr" {
  description = "Enter IP address for Load balancer Back End Addr pool association, for eg. 10.0.0.3: "
  type = string
  default = "10.0.0.3"
}

variable "VirtNetCIDR" {
  description = "Enter Network CIDR for the virtual network to be created, for eg. 10.0.0.0/22 :"
  type = string
  default = "10.0.0.0/22"
}

variable "subNet4virtNet" {
  description = "Enter a valid subnet CIDR to be created, for eg: 10.0.2.0/24: "
  type = string
  default = "10.0.2.0/24"
}

variable "vmCount" {
  description = "Enter the number of VMs to be created. For cost purposes, enter any number less than 6 and more than 1:"
  type = number
  default = "2"
}

variable "dataDiskCount" {
  description = "number of disks to be created"
  type = number
  default = 2
}

variable "feportstart" {
  description = "Enter a number for parameter frontend_port_start, for eg - 22000: "
  type = number
  default = "22000"
}

variable "feportend" {
  description = "Enter a number for parameter frontend_port_end, for eg - 22119: "
  type = number
  default = "22119"
}

variable "beport" {
  description = "Enter a number for parameter frontend_port_end, for eg - 22: "
  type = number
  default = "22"
}

variable "lbHttpPort" {
  description = "Enter a number for parameter frontend_port_end, for eg - 80: "
  type = number
  default = "80"
}

variable "instances" {
  description = "Enter the name of the VMs to be created in the comma seperated format for eg: AZ-VM-001, AZ-VM-002, AZ-VM-003 "
  type = list(string)
  default = ["AZ-VM-1", "AZ-VM-2", "AZ-VM-3"]
}

variable "nb_disks_per_instance" {
  description = "Enter the number of disks to be created per instance, for eg: 2"
  type = number
  default = "2"
}
