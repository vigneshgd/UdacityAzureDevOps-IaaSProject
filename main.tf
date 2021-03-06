locals {
  vm_datadiskdisk_count_map = { for k in toset(var.instances) : k => var.nb_disks_per_instance }
  luns                      = { for k in local.datadisk_lun_map : k.datadisk_name => k.lun }
  datadisk_lun_map = flatten([
    for vm_name, count in local.vm_datadiskdisk_count_map : [
      for i in range(count) : {
        datadisk_name = format("datadisk_%s_disk%02d", vm_name, i)
        lun           = i
      }
    ]
  ])
}

provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}rg01"
  location = var.location
}
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-VirtNetwork"
  address_space       = [var.VirtNetCIDR]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    project = "DevOpsIaaSProj"
  }
}
resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subNet4virtNet]
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-NSG"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allowIngressIntraSubnet"
	description				           = "allow access from subnet"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.subNet4virtNet
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allowIngressVirtNet"
	description				           = "allow access from virtual Net"
    priority                   = 505
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "allowIngressAzLoadBalancer"
	description				           = "security rule to allow traffic from Az load balancer"
    priority                   = 510
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "denyIngressFromInternet"
    description		   	         = "security rule to deny traffic from internet sources"
    priority                   = 600
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "denyIngressAnyOther"
	description				           = "security rule to deny traffic from all other sources"
    priority                   = 650
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allowEgressToSubnet"
    description		              = "security rule to allow traffic to subnet"
    priority                   = 501
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = var.subNet4virtNet
  }

  security_rule {
    name                       = "allowEgressToVirtNet"
    description		   		       = "security rule to allow traffic to virtual network"
    priority                   = 506
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "denyEgressToInternet"
    description		   		       = "security rule to deny traffic to internet"
    priority                   = 601
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "denyEgressToAny"
    description		   		       = "security rule to deny traffic to any"
    priority                   = 651
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "DevOpsIaaSProj"
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-main"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  domain_name_label   = azurerm_resource_group.main.name

  tags = {
    project = "DevOpsIaaSProj"
    environment = "staging"
  }
}

resource "azurerm_network_interface" "main" {
  count = var.vmCount
  name                = "AZ-VM-00-NIC-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-DevOpsLdBlncr"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}
resource "azurerm_lb_backend_address_pool" "bpepool" {
  loadbalancer_id     = azurerm_lb.main.id
  name            = "${var.prefix}-BackEndAddressPool"
}
resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = azurerm_resource_group.main.name
  name                           = "${var.prefix}-lbNatPool-ssh"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port_start            = var.feportstart
  frontend_port_end              = var.feportend
  backend_port                   = var.beport
  frontend_ip_configuration_name = "PublicIPAddress"
}
resource "azurerm_lb_probe" "main" {
  name                = "${var.prefix}-http-probe"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Http"
  request_path        = "/"
  port                = var.lbHttpPort
}

resource "azurerm_availability_set" "availset" {
  name                = "${var.prefix}-availability-set01"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    environment = "DevOpsIaaSProj"
  }
}

data "azurerm_image" "ubuntuImage" {
  name = "DevOpsUbuntu-18.04"
  resource_group_name = "PACKERRG"
}

output "image_id" {
  value = "/subscriptions/97753398-f685-4bc7-a3e9-9b86929f6c92/resourceGroups/PACKERRG/providers/Microsoft.Compute/images/DevOpsUbuntu-18.04"
}

resource "azurerm_linux_virtual_machine" "main" {
  count                 = length(var.instances)
  name                  = element(var.instances, count.index)
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  availability_set_id = azurerm_availability_set.availset.id
  size                = "Standard_D2s_v3"
  admin_username      = "var.username"
  admin_password      = "Password@1new"
  disable_password_authentication = "true"
  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  admin_ssh_key {
  username   = "var.username"
  public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    name                 = "osdisk-${element(var.instances, count.index)}-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    id = "/subscriptions/97753398-f685-4bc7-a3e9-9b86929f6c92/resourceGroups/PACKERRG/providers/Microsoft.Compute/images/DevOpsUbuntu-18.04"
  }
}

resource "azurerm_managed_disk" "managed_disk" {
    count                = length(var.instances) * var.nb_disks_per_instance
    name                 = element(var.instances, count.index)
    location             = azurerm_resource_group.main.location
    resource_group_name  = azurerm_resource_group.main.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "managed_disk_attach" {
  count              = length(var.instances) * var.nb_disks_per_instance
  managed_disk_id    = azurerm_managed_disk.managed_disk.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.main.*.id[ceil((count.index + 1) * 1.0 / var.nb_disks_per_instance) - 1]
  lun                = count.index + 10
  caching            = "ReadWrite"
}
