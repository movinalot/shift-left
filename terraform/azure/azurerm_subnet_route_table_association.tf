resource "azurerm_subnet_route_table_association" "subnet_route_table_association" {
  for_each = local.subnet_route_table_associations

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}
