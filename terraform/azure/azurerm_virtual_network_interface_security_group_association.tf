resource "azurerm_network_interface_security_group_association" "port1nsg" {
  for_each = local.network_interface_security_group_associations

  network_interface_id      = each.value.network_interface_id
  network_security_group_id = each.value.network_security_group_id
}
