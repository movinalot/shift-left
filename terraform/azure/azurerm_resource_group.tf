resource "azurerm_resource_group" "resource_group" {
  count = local.resource_group_exists ? 0 : 1

  name     = local.resource_group_name_combined
  location = local.location

  tags = {
    environment = local.environment_tag
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedOnDate"]
    ]
  }
}

data "azurerm_resource_group" "resource_group" {
  count = local.resource_group_exists ? 1 : 0
  name  = local.resource_group_name_combined
}

output "resource_group" {
  value = var.enable_output ? azurerm_resource_group.resource_group[*] : null
}
