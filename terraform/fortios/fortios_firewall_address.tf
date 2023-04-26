resource "fortios_firewall_address" "firewall_address" {
  for_each = local.firewall_addresses

  name = each.value.name

  interface = each.value.interface
  type      = each.value.type
  sdn       = each.value.sdn
  filter    = each.value.filter
}