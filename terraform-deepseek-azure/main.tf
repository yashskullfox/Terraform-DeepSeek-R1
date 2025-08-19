terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "deepseek-rg"
  location = var.azure_location
}

# 2. Create a Virtual Network (VNet)
resource "azurerm_virtual_network" "main" {
  name                = "deepseek-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# 3. Create a Subnet
resource "azurerm_subnet" "main" {
  name                 = "deepseek-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. Create a Public IP Address
resource "azurerm_public_ip" "main" {
  name                = "deepseek-public-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5. Create a Network Security Group (NSG - Firewall)
resource "azurerm_network_security_group" "main" {
  name                = "deepseek-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # WARNING: For production, restrict this
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OllamaAPI"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "11434"
    source_address_prefix      = "*" # WARNING: For production, restrict this
    destination_address_prefix = "*"
  }
}

# 6. Create a Network Interface (NIC)
resource "azurerm_network_interface" "main" {
  name                = "deepseek-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# 7. Associate the NSG with the NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# 8. Create the Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                  = "deepseek-vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128 # Increase OS disk size for models
  }

  # Specify the Ubuntu 22.04 LTS image
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Provide the cloud-init configuration, base64 encoded
  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
}

# 9. Output the public IP address
output "vm_public_ip" {
  value = azurerm_public_ip.main.ip_address
}