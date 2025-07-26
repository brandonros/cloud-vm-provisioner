terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "= 4.6.0"
    }
  }
}

resource "random_string" "id" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "resource_group1" {
  name     = "resource_group1_${random_string.id.result}" # random string seems to help with DNS caching at Azure level during reapplies?
  location = "East US 2"

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_network" "virtual_network1" {
  name                = "virtual_network1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group1.location
  resource_group_name = azurerm_resource_group.resource_group1.name

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.resource_group1.name
  virtual_network_name = azurerm_virtual_network.virtual_network1.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "network_security_group1" {
  name                = "network_security_group1"
  location = azurerm_resource_group.resource_group1.location
  resource_group_name = azurerm_resource_group.resource_group1.name
  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_public_ip" "public_ip1" {
  name                = "public_ip1"
  ip_version = "IPv4"
  resource_group_name = azurerm_resource_group.resource_group1.name
  location            = azurerm_resource_group.resource_group1.location
  allocation_method   = "Static"
  sku = "Standard" # TODO: why not basic?
  sku_tier = "Regional"
  ddos_protection_mode = "VirtualNetworkInherited"
  idle_timeout_in_minutes = 4

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_interface" "network_interface1" {
  name                = "network_interface1"
  resource_group_name = azurerm_resource_group.resource_group1.name
  location            = azurerm_resource_group.resource_group1.location

  ip_configuration {
    name                          = "ip_configuration1"
    primary                       = true
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = azurerm_public_ip.public_ip1.id
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_interface_security_group_association" "network_interface_security_group_association1" {
  network_interface_id      = azurerm_network_interface.network_interface1.id
  network_security_group_id = azurerm_network_security_group.network_security_group1.id
}

resource "azurerm_linux_virtual_machine" "virtual_machine1" {
  name                = "virtual_machine1"
  computer_name       = "vm1"  # _ not allowed
  resource_group_name = azurerm_resource_group.resource_group1.name
  location            = azurerm_resource_group.resource_group1.location
  size                = "Standard_D4_v5" # 4 vCPU, 16 GiB memory, had to request quota upgrade approval on Pay-As-You-Go subscription, $0.1920/hr
  admin_username      = "debian"
  network_interface_ids = [
    azurerm_network_interface.network_interface1.id,
  ]

  admin_ssh_key {
    username   = "debian"
    public_key = file("~/.ssh/id_rsa.pub") # ssh-ed25519 SSH key is not supported
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
