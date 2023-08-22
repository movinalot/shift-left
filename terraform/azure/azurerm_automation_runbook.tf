resource "azurerm_automation_runbook" "automation_runbook" {
  for_each = local.automation_runbooks

  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  name                    = each.value.name
  automation_account_name = each.value.automation_account_name
  log_verbose             = each.value.log_verbose
  log_progress            = each.value.log_progress
  runbook_type            = each.value.runbook_type

  publish_content_link {
    uri = each.value.publish_content_link_uri
  }
}

output "automation_runbooks" {
  value = var.enable_output ? azurerm_automation_runbook.automation_runbook[*] : null
}
