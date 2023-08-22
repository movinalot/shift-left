resource "azurerm_automation_webhook" "automation_webhook" {
  for_each = local.automation_webhooks

  resource_group_name = each.value.resource_group_name

  name                    = each.value.name
  automation_account_name = each.value.automation_account_name
  expiry_time             = each.value.expiry_time
  enabled                 = each.value.enabled
  runbook_name            = each.value.runbook_name

  lifecycle {
    ignore_changes = [
      expiry_time
    ]
  }
}

output "automation_webhooks" {
  value = var.enable_output ? azurerm_automation_webhook.automation_webhook[*] : null
  sensitive = true
}
