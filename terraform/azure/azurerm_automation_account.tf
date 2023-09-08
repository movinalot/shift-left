resource "azurerm_automation_account" "automation_account" {
  for_each = local.automation_accounts

  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  name     = each.value.name
  sku_name = each.value.sku_name

  identity {
    type = each.value.identity_type
  }
}

output "automation_accounts" {
  value     = var.enable_output ? azurerm_automation_account.automation_account[*] : null
  sensitive = true
}
