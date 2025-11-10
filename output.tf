############################
# ======= OUTPUTS ======== #
############################

# Map tên VM -> Public IP
output "public_ips" {
  description = "Public IP của từng VM theo tên"
  value       = { for name in var.vm_names : name => azurerm_public_ip.pip[name].ip_address }
}

# Map tên VM -> lệnh SSH
output "ssh_commands" {
  description = "Lệnh SSH cho từng VM"
  value       = {
    for name in var.vm_names :
    name => "ssh ${var.admin_username}@${azurerm_public_ip.pip[name].ip_address}"
  }
}