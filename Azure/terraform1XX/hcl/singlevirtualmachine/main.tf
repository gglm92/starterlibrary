#################################################################
# Terraform template that will deploy:
#    * Ubuntu VM on Microsoft Azure
#
# Version: 2.4
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2020.
#
#################################################################

#########################################################
# Define the Azure provider
#########################################################
provider "azurerm" {
  features {}
}

#########################################################
# Helper module for tagging
#########################################################
module "camtags" {
  source = "../Modules/camtags"
}

#########################################################
# Define the variables
#########################################################
variable "azure_region" {
  description = "Azure region to deploy infrastructure resources"
  default     = "West US"
}

variable "name_prefix" {
  description = "Prefix of names for Azure resources"
  default     = "singleVM"
}

variable "admin_user" {
  description = "Name of an administrative user to be created in virtual machine in this deployment"
  default     = "ibmadmin"
}

variable "admin_user_password" {
  description = "Password of the newly created administrative user"
}

variable "user_public_key" {
  description = "Public SSH key used to connect to the virtual machine"
}

#########################################################
# Deploy the network resources
#########################################################
resource "random_id" "default" {
  byte_length = "4"
}

resource "azurerm_resource_group" "default" {
  name     = "${var.name_prefix}-${random_id.default.hex}-rg"
  location = var.azure_region
  tags     = module.camtags.tagsmap
}

resource "azurerm_virtual_network" "default" {
  name                = "${var.name_prefix}-${random_id.default.hex}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.default.name

  tags = {
    environment = "Terraform Basic VM"
  }
}

resource "azurerm_subnet" "vm" {
  name                 = "${var.name_prefix}-subnet-${random_id.default.hex}-vm"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "vm" {
  name                = "${var.name_prefix}-${random_id.default.hex}-vm-pip"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Static"
  tags                = module.camtags.tagsmap
}

resource "azurerm_network_security_group" "vm" {
  depends_on		  = [azurerm_network_interface.vm]
  name                = "${var.name_prefix}-${random_id.default.hex}-vm-nsg"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.default.name
  tags                = module.camtags.tagsmap

  security_rule {
    name                       = "ssh-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "custom-tcp-allow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.name_prefix}-${random_id.default.hex}-vm-nic1"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.default.name

  ip_configuration {
    name                          = "${var.name_prefix}-${random_id.default.hex}-vm-nic1-ipc"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
  tags                = module.camtags.tagsmap
}

resource "azurerm_network_interface_security_group_association" "vm" {
  depends_on		  = [azurerm_network_interface.vm, azurerm_network_security_group.vm]
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

#########################################################
# Deploy the storage resources
#########################################################
resource "azurerm_storage_account" "default" {
  name                     = format("st%s", random_id.default.hex)
  resource_group_name      = azurerm_resource_group.default.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = module.camtags.tagsmap

}

resource "azurerm_storage_container" "default" {
  name                  = "default-container"
  storage_account_name  = azurerm_storage_account.default.name
  container_access_type = "private"
}

#########################################################
# Deploy the virtual machine resource
#########################################################
resource "azurerm_virtual_machine" "vm" {
  depends_on			      = [azurerm_network_interface_security_group_association.vm]
  name                  = "${var.name_prefix}-vm"
  location              = var.azure_region
  resource_group_name   = azurerm_resource_group.default.name
  network_interface_ids = [azurerm_network_interface.vm.id]
  vm_size = "Standard_D8s_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.name_prefix}-vm-os-disk1"
    vhd_uri       = "${azurerm_storage_account.default.primary_blob_endpoint}${azurerm_storage_container.default.name}/${var.name_prefix}-vm-os-disk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.name_prefix}-vm"
    admin_username = var.admin_user
    admin_password = var.admin_user_password
  }

  os_profile_linux_config {
    disable_password_authentication = false

    # ssh_keys {
    #   path     = "/home/${var.admin_user}/.ssh/authorized_keys"
    #   key_data = var.user_public_key
    # }
  }

  tags             = module.camtags.tagsmap
}

#########################################################
# Define el bloque de locales
#########################################################
locals {
  # Mapa de prefijos CIDR a máscaras de subred
  cidr_netmask_map = {
    32 = "255.255.255.255"
    31 = "255.255.255.254"
    30 = "255.255.255.252"
    29 = "255.255.255.248"
    28 = "255.255.255.240"
    27 = "255.255.255.224"
    26 = "255.255.255.192"
    25 = "255.255.255.128"
    24 = "255.255.255.0"
    23 = "255.255.254.0"
    22 = "255.255.252.0"
    21 = "255.255.248.0"
    20 = "255.255.240.0"
    19 = "255.255.224.0"
    18 = "255.255.192.0"
    17 = "255.255.128.0"
    16 = "255.255.0.0"
    15 = "255.254.0.0"
    14 = "255.252.0.0"
    13 = "255.248.0.0"
    12 = "255.240.0.0"
    11 = "255.224.0.0"
    10 = "255.192.0.0"
    9  = "255.128.0.0"
    8  = "255.0.0.0"
    7  = "254.0.0.0"
    6  = "252.0.0.0"
    5  = "248.0.0.0"
    4  = "240.0.0.0"
    3  = "224.0.0.0"
    2  = "192.0.0.0"
    1  = "128.0.0.0"
    0  = "0.0.0.0"
  }

  # Extrae el tamaño de prefijo de la subred (por ejemplo, "24" de "10.0.1.0/24")
  subnet_prefix_length = tonumber(split("/", azurerm_subnet.vm.address_prefixes[0])[1])

  # Convierte el tamaño de prefijo en la máscara de subred usando el mapa
  subnet_netmask = local.cidr_netmask_map[local.subnet_prefix_length]
}

#########################################################
# Output
#########################################################
output "azure_vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "azure_vm_private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}

# Hostname of the VM
output "azure_vm_hostname" {
  value = one(azurerm_virtual_machine.vm.os_profile[*].computer_name)
  sensitive = true
}

# Operating System of the VM
output "azure_vm_os" {
  value = one(azurerm_virtual_machine.vm.storage_image_reference[*].offer)
}

# Operating System Version of the VM
output "azure_vm_os_version" {
  value = one(azurerm_virtual_machine.vm.storage_image_reference[*].sku)
}

# Gateway of the VM's subnet (default gateway)
output "azure_vm_gateway" {
  value = azurerm_subnet.vm.address_prefixes[0]
}

# Netmask of the VM's subnet
output "azure_vm_netmask" {
  value = local.subnet_netmask
}