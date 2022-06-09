terraform {

  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Create resource group
resource "azurerm_resource_group" "diploma" {
  name      = var.resource_group_name
  location  = var.resource_group_location
}

# Create a rule to prevent the deletion of a resource group from azure portal
resource "azurerm_management_lock" "resource-group-lock" {
  name       = "resource-group-lock"
  scope      = azurerm_resource_group.diploma.id
  lock_level = "CanNotDelete"
  notes      = "This Resource Group is CanNotDelete"
}

# Create virtual network for all environments
resource "azurerm_virtual_network" "internal_network" {
  name                = "internal_net"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.diploma.location
  resource_group_name = azurerm_resource_group.diploma.name
}

# Create subnet for Jenkins 
resource "azurerm_subnet" "subnet_for_jenkins" {
  name                 = "subnet_for_jenkins"
  resource_group_name  = azurerm_resource_group.diploma.name
  virtual_network_name = azurerm_virtual_network.internal_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Jenkins public IPs
resource "azurerm_public_ip" "Jenkins_IP" {
  name                         = "JenkinsIP"
  location                     = azurerm_resource_group.diploma.location
  resource_group_name          = azurerm_resource_group.diploma.name
  allocation_method            = "Static"
}

# Create Network Security Group and rule for Jenkins environment
resource "azurerm_network_security_group" "Jenkins_NSG" {
  name                = "JenkinsNSG"
  location            = azurerm_resource_group.diploma.location
  resource_group_name = azurerm_resource_group.diploma.name
  
  dynamic "security_rule" {
    for_each = var.jenkins_nsg_rules
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }
}

# Create Jenkins network interface
resource "azurerm_network_interface" "Jenkins_Net_interface" {
  name                = "Jenkins_NI"
  location            = azurerm_resource_group.diploma.location
  resource_group_name = azurerm_resource_group.diploma.name

  ip_configuration {
    name                          = "NicConfigurationforJenkins"
    subnet_id                     = azurerm_subnet.subnet_for_jenkins.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Jenkins_IP.id
  }
}

# Connect the Jenkins security group to the network interface
resource "azurerm_network_interface_security_group_association" "Connect_Jenkins_NSG_to_NI" {
  network_interface_id      = azurerm_network_interface.Jenkins_Net_interface.id
  network_security_group_id = azurerm_network_security_group.Jenkins_NSG.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.diploma.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.diploma.location
  resource_group_name      = azurerm_resource_group.diploma.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create Jenkins virtual machine
resource "azurerm_linux_virtual_machine" "Jenkins_VM" {
  name                  = "Jenkins"
  location              = azurerm_resource_group.diploma.location
  resource_group_name   = azurerm_resource_group.diploma.name
  network_interface_ids = [azurerm_network_interface.Jenkins_Net_interface.id]
  # Production size
  //size                  = "Standard_DS2_v2"
  # Study size
  size                  = "Standard_B1s"

  os_disk {
    name                 = "Jenkins_Disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "jenkins"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false

  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }

  provisioner "remote-exec" {
        connection {
            host = self.public_ip_address
            type     = "ssh"
            user     = var.username
            password = var.password
        }

        inline = [
        "sudo apt-get update -y",
        "sudo apt-get install -y openjdk-11-jdk",
        "sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
        "sudo echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
        "sudo apt-get update -y",
        "sudo apt-get install -y jenkins"
        ]
    }  
}

# Write the ssh key to a local file
resource "local_file" "private_key" {
    content  = tls_private_key.example_ssh.private_key_pem
    filename = "id_rsa"
}