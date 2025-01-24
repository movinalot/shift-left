resource "fortios_system_automationaction" "system_automationaction" {
  for_each = local.system_automationaction

  name = each.value.name

  description = each.value.description
  action_type = each.value.action_type
  protocol    = each.value.protocol

  uri       = each.value.uri
  http_body = each.value.http_body
  port      = each.value.port

  dynamic "http_headers" {
    for_each = local.http_headers

    content {
      key   = http_headers.value.key
      value = http_headers.value.value
    }
  }

  verify_host_cert = each.value.verify_host_cert
}

output "system_automationactions" {
  value     = var.enable_output ? fortios_system_automationaction.system_automationaction[*] : null
  sensitive = true
}
