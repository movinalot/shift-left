resource "fortios_system_automationstitch" "system_automationstitch" {
  for_each = local.system_automationstitches

  name = each.value.name

  description = each.value.description
  status      = each.value.status
  trigger     = each.value.trigger

  dynamic "actions" {
    for_each = each.value.actions

    content {
      action = actions.value.action
    }
  }
}

output "system_automationstitches" {
  value = var.enable_output ? fortios_system_automationstitch.system_automationstitch[*] : null
}
