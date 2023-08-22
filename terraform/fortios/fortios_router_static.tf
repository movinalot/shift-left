resource "fortios_router_static" "router_static" {
  for_each = var.static_routes

  device  = each.value.device
  dst     = each.value.dst
  gateway = each.value.gateway
  status  = each.value.status
}

output "router_statics" {
  value = var.enable_output ? fortios_router_static.router_static[*] : null
}
