resource "fortios_system_sdnconnector" "system_sdnconnector" {
  for_each = local.sdn_connectors

  name = each.value.name

  azure_region     = each.value.azure_region
  status           = each.value.status
  type             = each.value.type
  update_interval  = each.value.update_interval
  use_metadata_iam = each.value.use_metadata_iam
  subscription_id  = each.value.subscription_id
  resource_group   = each.value.resource_group
}

output "system_sdnconnectors" {
  value = var.enable_output ? fortios_system_sdnconnector.system_sdnconnector[*] : null
  sensitive = true
}