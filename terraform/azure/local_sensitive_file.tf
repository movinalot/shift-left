locals {
  fortigate_vars = format(
    "%s = \"%s\"\n%s = \"%s\"\n%s = \"%s\"\n%s = \"%s\"\n%s = \"%s\"\n%s = \"%s\"\n%s = { \"%s\" = { device = \"%s\", dst = \"%s\", gateway = \"%s\", status = \"%s\" } }",
    "fortigate_api_token ", random_string.string.id,
    "fortigate_ip_or_fqdn", azurerm_public_ip.public_ip["pip-fgt"].ip_address,
    "resource_group_name ", local.resource_group_name,
    "route_table_name    ", azurerm_route_table.route_table["rt-protected"].name,
    "next_hop_ip         ", azurerm_network_interface.network_interface["nic-fgt-port2"].private_ip_address,
    "webhook             ", azurerm_automation_webhook.automation_webhook["Update-RouteTable_webhook"].uri,
    "static_routes       ", "protected", "port2", azurerm_subnet.subnet["snet-protected"].address_prefixes[0], cidrhost(azurerm_subnet.subnet["snet-internal"].address_prefixes[0], 1), "enable"
  )
}

resource "local_sensitive_file" "file" {
  filename = "../fortios/fortigate.auto.tfvars"
  content  = local.fortigate_vars
}

resource "local_sensitive_file" "file_automation_action" {
  filename = "../fortios/fortigate_automation_action_cli.cfg"
  content  = <<-EOT
config system automation-action
    edit "routetableupdate"
        set description "Update Route Table for MicroSegmentation"
        set action-type webhook
        set protocol https
        set uri "${replace(azurerm_automation_webhook.automation_webhook["Update-RouteTable_webhook"].uri, "https://", "")}"
        set http-body "{\"action\":\"%%log.action%%\", \"addr\":\"%%log.addr%%\"}"
        set port 443
        config http-headers
            edit 1
                set key "ResourceGroupName"
                set value "${local.resource_group_name}"
            next
            edit 2
                set key "RouteTableName"
                set value "${azurerm_route_table.route_table["rt-protected"].name}"
            next
            edit 3
                set key "RouteNamePrefix"
                set value "microseg"
            next
            edit 4
                set key "NextHopIp"
                set value "${azurerm_network_interface.network_interface["nic-fgt-port2"].private_ip_address}"
            next
        end
        set verify-host-cert disable
    next 
end
EOT
}

resource "local_sensitive_file" "tempalte_file" {
  for_each = local.virtual_machines
  filename = format("../fortios/fortios_%s.cfg", each.value.name)
  content = templatefile("${each.value.os_profile_custom_data}", {
    hostname                     = each.value.name
    api_key                      = each.value.os_profile_custom_data_api_key
    license_type                 = each.value.os_profile_custom_data_license_type
    license_file                 = each.value.os_profile_custom_data_license_file
    license_token                = each.value.os_profile_custom_data_license_token
    automation_stitch_action_uri = local.automation_stitch_action_uri
    fortigate_access_token       = local.fortigate_access_token
  })
}