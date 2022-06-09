variable "resource_group_name" {
  default       = "diploma"
  description   = "Resource group name in azure"
}

variable "resource_group_location" {
  default       = "westeurope"
  description   = "Location of the resource group."
}

variable "username" {
  default       = "azureuser"
  description   = "Username for access to VM"
}

variable "password" {
  default       = "SuperSecur!ty@Pa$$word!"
  description   = "Password for access to VM"
}

variable "jenkins_nsg_rules" {
    type = list(object({
        name                       = string
        priority                   = string
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
    }))
}