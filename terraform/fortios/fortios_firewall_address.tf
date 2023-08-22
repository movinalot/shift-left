resource "fortios_firewall_address" "firewall_address" {
  for_each = local.firewall_addresses

  name = each.value.name

  associated_interface = each.value.associated_interface
  type                 = each.value.type
  sdn                  = each.value.sdn
  filter               = each.value.filter
}

output "firewall_addresses" {
  value = var.enable_output ? fortios_firewall_address.firewall_address[*] : null
}
