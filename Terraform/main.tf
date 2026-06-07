#region Terraform feature block
provider "azurerm" {
  features {

  }
  use_oidc = true
}
#endregion

#region local variables
locals {
  # Everything related to the virtual network
  resource_group_name = "nestedvm-rg"
  location            = "West Europe"
  vnetname            = "nestedvm-vnet"
  addresspace         = ["172.16.0.0/16"]
  subnetname          = "nestedvm-snet"
  addressprefixes     = ["172.16.0.0/24"]

  # Everything related to the load balancer
  pipname             = "nestedvm-pip"
  lbname              = "nestedvm-lb"

  # Everything related to the network security group
  nsgName             = "nestedvm-nsg"
}
#endregion

#region Virtual Network
resource "azurerm_virtual_network" "udvnet" {
  name                = local.vnetname
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = local.addresspace

  tags = {
    "Function" = "VNet for Nested Virtualization Lab"
  }
}

resource "azurerm_subnet" "nestedvm_subnet" {
  name                 = local.subnetname
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.udvnet.name
  address_prefixes     = local.addressprefixes
}
#endregion

#region Load Balancer
#region Public IP
resource "azurerm_public_ip" "lbpip" {
  name                = local.pipname
  location            = local.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    "Function" = "Public IP for the loadbalancer"
  }
}
#endregion

#region Load Balancer
resource "azurerm_lb" "lb" {
  name                = local.lbname
  location            = local.location
  resource_group_name = local.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lbpip.id
  }

  tags = {
    "Function" = "Loadbalancer for the Nested Virtualization Lab"
  }
}
#endregion

  #region Backend Address Pool
resource "azurerm_lb_backend_address_pool" "bap" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "NestedVMBackendPool"
}
#endregion
#region Probe
resource "azurerm_lb_probe" "ssh" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "rdp-probe"
  port            = 3389
}
#endregion

#region Nat Rule RDP
resource "azurerm_lb_nat_rule" "rdp" {
  resource_group_name            = local.resource_group_name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "rdp-nat-rule"
  protocol                       = "Tcp"
  frontend_port                  = 61412
  backend_port                   = 3389
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
}
#endregion

#region Outbound Rule
resource "azurerm_lb_outbound_rule" "internet" {
  name                    = "Internet"
  loadbalancer_id         = azurerm_lb.lb.id
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bap.id

  frontend_ip_configuration {
    name = azurerm_lb.lb.frontend_ip_configuration[0].name
  }
}
#endregion
#endregion

#region Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = local.nsgName
  location            = local.location
  resource_group_name = local.resource_group_name
  tags = {
    environment = "NSG for Nested Virtualization Lab"
  }
}

resource "azurerm_network_security_rule" "rdp" {
  name                        = "Allow-RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "172.16.0.4"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
#endregion
