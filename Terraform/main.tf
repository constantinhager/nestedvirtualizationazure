#region local variables
locals {
  # Everything related to the virtual network
  resource_group_name = "nestedvm-rg"
  location            = "West Europe"
  vnetname            = "nestedvm-vnet"
  addresspace         = ["10.1.0.0/16"]
  subnetname          = "nestedvm-subnet"
  addressprefixes     = ["10.1.1.0/24"]
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

resource "azurerm_subnet" "vmcontainersubnet" {
  name                 = local.subnetname
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.udvnet.name
  address_prefixes     = local.addressprefixes
}
#endregion
