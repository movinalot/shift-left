locals {
  server_roles = ["AppServer", "DbServer", "WebServer"]

  sdn_connectors = {
    "AzureSDN" = {
      name = "AzureSDN"

      azure_region     = "global"
      status           = "enable"
      type             = "azure"
      update_interval  = 60
      use_metadata_iam = "enable"
      subscription_id  = ""
      resource_group   = ""
    }
  }

  firewall_addresses = {
    for role in local.server_roles : "${role}s" => {
      name                 = "${role}s"
      associated_interface = "port2"
      type                 = "dynamic"
      sdn                  = fortios_system_sdnconnector.system_sdnconnector["AzureSDN"].name
      filter               = "Tag.ComputeType=${role}"
    }
  }

  firewall_policys = {
    "webserver2webserver" = {
      policyid = 1

      name = "webser2webserver"

      action     = "accept"
      logtraffic = "utm"
      nat        = "disable"
      status     = "enable"
      schedule   = "always"

      srcintf = [{ name = "port2" }]
      dstintf = [{ name = "port2" }]
      srcaddr = [{ name = fortios_firewall_address.firewall_address["WebServers"].name }]
      dstaddr = [{ name = fortios_firewall_address.firewall_address["WebServers"].name }]
      service = [{ name = "ALL" }]
    }
  }

  http_headers = [
    { key = "ResourceGroupName", value = var.resource_group_name },
    { key = "RouteTableName", value = var.route_table_name },
    { key = "RouteNamePrefix", value = "microseg" },
    { key = "NextHopIp", value = var.next_hop_ip },
  ]

  system_automationtriggers = {
    for role in local.server_roles : "${role} Existence" => {
      name        = "${role} Existence"
      description = "Tag ComputeType with value of ${role} updates route table."
      event_type  = "event-log"

      logid_block = [{ id = 53200 }, { id = 53201 }]
      fields      = [{ name = "cfgobj", value = "${role}s" }]
    }
  }

  system_automationaction = {
    "routetableupdate" = {
      name             = "routetableupdate"
      description      = "Update Route Table for MicroSegmentation"
      action_type      = "webhook"
      protocol         = "https"
      uri              = replace(var.webhook, "https://", "")
      http_body        = "{\"action\":\"%%log.action%%\", \"addr\":\"%%log.addr%%\"}"
      port             = 443
      verify_host_cert = "disable"
    }
  }

  system_automationstitches = {
    for role in local.server_roles : "routetableupdate-${role}s" => {
      name        = "routetableupdate-${role}s"
      description = "Update route table for ${trimsuffix(role, "Server")} Servers"
      status      = "enable"
      trigger     = fortios_system_automationtrigger.system_automationtrigger["${role} Existence"].name

      actions = [
        { action = fortios_system_automationaction.system_automationaction["routetableupdate"].name }
      ]
    }
  }
}
