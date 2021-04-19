provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
  tags = {
    environment = "DevOpsIaaSProj"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    environment = "DevOpsIaaSProj"
  }
}

resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
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
    source_address_prefix      = "10.0.2.0/24"
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
    destination_address_prefix = "10.0.2.0/24"
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
  name                = "${var.prefix}-pubip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "DevOpsIaaSProj"
  }
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "${var.prefix}-privip"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id          = azurerm_public_ip.main.id
  }
  tags = {
    environment = "DevOpsIaaSProj"
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-DevOpsLdBlncr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  frontend_ip_configuration {
    name                 = "${var.prefix}-FrntEndIp"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  tags = {
    environment = "DevOpsIaaSProj"
  }
}
resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.prefix}-BackEndAddressPool"
  loadbalancer_id = azurerm_lb.main.id
}

data "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.prefix}-LbBkEndAddrPool"
  loadbalancer_id = data.azurerm_lb.main.id
}

data "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-VirtNetwork"
  resource_group_name = azurerm_resource_group.main.name
}

data "azurerm_lb" "example" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_lb_backend_address_pool_address" "main" {
  name                    = "${var.prefix}-AddrPoolAssociation"
  backend_address_pool_id = data.azurerm_lb_backend_address_pool.main.id
  virtual_network_id      = data.azurerm_virtual_network.main.id
  ip_address              = "var.LbBeAddrPoolAssociationIp"
  tags = {
    environment = "DevOpsIaaSProj"
  }
}

data "azurerm_public_ip" "main" {
  name                = azurerm_public_ip.main.name
  resource_group_name = azurerm_linux_virtual_machine.main.resource_group_name
}

output "public_ip_address" {
  value = data.azurerm_public_ip.main.ip_address
}

resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-availability-set"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    environment = "DevOpsIaaSProj"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  availability_set_id			  = azurerm_availability_set.main.id
  size							  = Standard_D2s_v3
  admin_username                  = "var.username"
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "DevOpsIaaSProj"
  }
}
}

resource "azurerm_managed_disk" "main" {
  name                 = "${var.prefix}-ManagedDisk01"
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environment = "DevOpsIaaSProj"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  managed_disk_id    = azurerm_managed_disk.main.id
  virtual_machine_id = azurerm_virtual_machine.main.id
  lun                = "1"
  caching            = "ReadWrite"
  create_option		 = "Attach"
}

data "azurerm_template_spec_version" "main" {
  name                = "${var.prefix}-az-template-spec"
  resource_group_name  = azurerm_resource_group.main.name
  version             = "v3.4.0"
}

resource "azurerm_resource_group_template_deployment" "main" {
  name                     = "${var.prefix}-RGDeploymentTemplate"
  resource_group_name      = azurerm_resource_group.main.name
  deployment_mode          = "Complete"
  template_spec_version_id = data.azurerm_template_spec_version.main.id
}
