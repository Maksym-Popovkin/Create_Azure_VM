output "Jenkins_IP" {
  value = azurerm_linux_virtual_machine.Jenkins_VM.public_ip_address
}