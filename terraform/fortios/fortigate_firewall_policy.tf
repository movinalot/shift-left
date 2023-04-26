resource "fortios_firewall_policy" "firewall_policy" {
  for_each = local.firewall_policys

  name = each.value.name

  action     = each.value.action
  logtraffic = each.value.logtraffic
  nat        = each.value.nat
  status     = each.value.status
  schedule   = each.value.schedule

  dynamic "srcintf" {
    for_each = each.value.srcintf

    content {
      name = srcintf.value.name
    }
  }

  dynamic "dstintf" {
    for_each = each.value.dstintf

    content {
      name = dstintf.value.name
    }
  }

  dynamic "srcaddr" {
    for_each = each.value.srcaddr

    content {
      name = srcaddr.value.name
    }
  }

  dynamic "dstaddr" {
    for_each = each.value.dstaddr

    content {
      name = dstaddr.value.name
    }
  }

  dynamic "service" {
    for_each = each.value.service

    content {
      name = service.value.name
    }
  }
}
