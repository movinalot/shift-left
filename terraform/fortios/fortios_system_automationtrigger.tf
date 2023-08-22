resource "fortios_system_automationtrigger" "system_automationtrigger" {
  for_each = local.system_automationtriggers

  name        = each.value.name
  description = each.value.description
  event_type  = each.value.event_type

  dynamic "logid_block" {
    for_each = each.value.logid_block
    content {
      id = logid_block.value.id
    }
  }

  dynamic "fields" {
    for_each = each.value.fields
    content {
      name  = fields.value.name
      value = fields.value.value
    }
  }
}

output "system_automationtriggers" {
  value = var.enable_output ? fortios_system_automationtrigger.system_automationtrigger[*] : null
}
