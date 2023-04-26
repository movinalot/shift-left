locals {
  resource_group_exists        = true
  resource_group_name_combined = "${local.username}-${var.resource_group_name_suffix}"

  location = "eastus"

  resource_group_name     = local.resource_group_exists ? data.azurerm_resource_group.resource_group.0.name : azurerm_resource_group.resource_group.0.name
  resource_group_location = local.resource_group_exists ? data.azurerm_resource_group.resource_group.0.location : azurerm_resource_group.resource_group.0.location
  resource_group_id       = local.resource_group_exists ? data.azurerm_resource_group.resource_group.0.id : azurerm_resource_group.resource_group.0.id

  username = var.username
  password = "Fortinet123#"

  environment_tag = "Terraform Single FortiGate"

  automation_accounts = {
    format("aa-%s", local.username) = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name          = format("aa-%s", local.username)
      sku_name      = "Basic"
      identity_type = "SystemAssigned"
    }
  }

  automation_runbooks = {
    "Update-RouteTable" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name                    = "Update-RouteTable"
      automation_account_name = azurerm_automation_account.automation_account[format("aa-%s", local.username)].name
      log_verbose             = "true"
      log_progress            = "true"
      runbook_type            = "PowerShell"

      publish_content_link_uri = "https://raw.githubusercontent.com/FortinetSecDevOps/technical-recipe-azure-fgt-automation-stitch/main/PowerShell/Update-RouteTable.ps1"
    }
  }

  automation_webhooks = {
    "Update-RouteTable_webhook" = {
      resource_group_name = local.resource_group_name

      name                    = "Update-RouteTable_webhook"
      automation_account_name = azurerm_automation_account.automation_account[format("aa-%s", local.username)].name
      expiry_time             = timeadd(timestamp(), "8760h")
      enabled                 = true
      runbook_name            = azurerm_automation_runbook.automation_runbook["Update-RouteTable"].name
    }
  }

  public_ips = {
    "pip-fgt" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name              = "pip-fgt"
      allocation_method = "Static"
      sku               = "Standard"
    }
  }

  route_tables = {
    "rt-protected" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name = "rt-protected"
    }
  }

  routes = {
    "default" = {
      resource_group_name = local.resource_group_name

      name                   = "default"
      route_table_name       = azurerm_route_table.route_table["rt-protected"].name
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_network_interface.network_interface["nic-fgt-port2"].private_ip_address
    }
  }

  subnet_route_table_associations = {
    "snet-protected" = {
      subnet_id      = azurerm_subnet.subnet["snet-protected"].id
      route_table_id = azurerm_route_table.route_table["rt-protected"].id
    }
  }

  storage_accounts = {
    format("st%s", local.username) = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name                     = substr(format("st%s", local.username), 0, 24)
      account_replication_type = "LRS"
      account_tier             = "Standard"

      min_tls_version = "TLS1_2"
    }
  }

  vm_image = {
    "fortigate" = {
      publisher = "fortinet"
      offer     = "fortinet_fortigate-vm_v5"
      vm_size   = "Standard_DS2_v2"
      version   = "latest"                   # can also be a version, e.g. 6.4.9, 7.0.6, 7.2.0, etc. latest is latest
      sku       = "fortinet_fg-vm_payg_2022" # can be byol|flex - fortinet_fg-vm2 or payg - "fortinet_fg-vm_payg_2022"
    }
    "linux_vm" = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      vm_size   = "Standard_F2"
      version   = "latest"
      sku       = "16.04-LTS"
    }
  }

  virtual_networks = {
    "vnet-fgt" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name          = "vnet-fgt"
      address_space = ["10.1.0.0/16"]
    }
  }

  subnets = {
    "snet-external" = {
      resource_group_name = local.resource_group_name

      name                 = "snet-external"
      virtual_network_name = azurerm_virtual_network.virtual_network["vnet-fgt"].name
      address_prefixes     = [cidrsubnet(azurerm_virtual_network.virtual_network["vnet-fgt"].address_space[0], 8, 0)]
    }
    "snet-internal" = {
      resource_group_name = local.resource_group_name

      name                 = "snet-internal"
      virtual_network_name = azurerm_virtual_network.virtual_network["vnet-fgt"].name
      address_prefixes     = [cidrsubnet(azurerm_virtual_network.virtual_network["vnet-fgt"].address_space[0], 8, 1)]
    }
    "snet-protected" = {
      resource_group_name = local.resource_group_name

      name                 = "snet-protected"
      virtual_network_name = azurerm_virtual_network.virtual_network["vnet-fgt"].name
      address_prefixes     = [cidrsubnet(azurerm_virtual_network.virtual_network["vnet-fgt"].address_space[0], 8, 2)]
    }
  }

  network_interfaces = {
    "nic-fgt-port1" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name                          = "nic-fgt-port1"
      enable_ip_forwarding          = true
      enable_accelerated_networking = true

      ip_configurations = [
        {
          name                          = "ipconfig1"
          primary                       = true
          subnet_id                     = azurerm_subnet.subnet["snet-external"].id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost(azurerm_subnet.subnet["snet-external"].address_prefixes[0], 4)
          public_ip_address_id          = azurerm_public_ip.public_ip["pip-fgt"].id
        }
      ]
    }
    "nic-fgt-port2" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name                          = "nic-fgt-port2"
      enable_ip_forwarding          = true
      enable_accelerated_networking = true

      ip_configurations = [
        {
          name                          = "ipconfig1"
          primary                       = true
          subnet_id                     = azurerm_subnet.subnet["snet-internal"].id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost(azurerm_subnet.subnet["snet-internal"].address_prefixes[0], 4)
          public_ip_address_id          = null
        }
      ]
    }
    "nic-linux-1-eth1" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name                          = "nic-linux-1-eth1"
      enable_ip_forwarding          = false
      enable_accelerated_networking = false

      ip_configurations = [
        {
          name                          = "ipconfig1"
          primary                       = true
          subnet_id                     = azurerm_subnet.subnet["snet-protected"].id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost(azurerm_subnet.subnet["snet-protected"].address_prefixes[0], 4)
          public_ip_address_id          = null
        }
      ]
    }
    "nic-linux-2-eth1" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name                          = "nic-linux-2-eth1"
      enable_ip_forwarding          = false
      enable_accelerated_networking = false

      ip_configurations = [
        {
          name                          = "ipconfig1"
          primary                       = true
          subnet_id                     = azurerm_subnet.subnet["snet-protected"].id
          private_ip_address_allocation = "Static"
          private_ip_address            = cidrhost(azurerm_subnet.subnet["snet-protected"].address_prefixes[0], 5)
          public_ip_address_id          = null
        }
      ]
    }
  }

  network_security_groups = {
    "nsg-external" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name = "nsg-external"
    }
    "nsg-internal" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name = "nsg-internal"
    }
  }

  network_security_rules = {
    "nsgsr-external-ingress" = {
      resource_group_name = local.resource_group_name

      name                        = "nsgsr-external-ingress"
      priority                    = 1001
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "*"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
      network_security_group_name = azurerm_network_security_group.network_security_group["nsg-external"].name
    },
    "nsgsr-external-egress" = {
      resource_group_name = local.resource_group_name

      name                        = "nsgsr-external-egress"
      priority                    = 1002
      direction                   = "Outbound"
      access                      = "Allow"
      protocol                    = "*"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
      network_security_group_name = azurerm_network_security_group.network_security_group["nsg-external"].name
    },
    "nsgsr-internal-ingress" = {
      resource_group_name = local.resource_group_name

      name                        = "nsgsr-internal-ingress"
      priority                    = 1001
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "*"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
      network_security_group_name = azurerm_network_security_group.network_security_group["nsg-internal"].name
    },
    "nsgsr-internal-egress" = {
      resource_group_name = local.resource_group_name

      name                        = "nsgsr-internal-egress"
      priority                    = 1002
      direction                   = "Outbound"
      access                      = "Allow"
      protocol                    = "*"
      source_port_range           = "*"
      destination_port_range      = "*"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
      network_security_group_name = azurerm_network_security_group.network_security_group["nsg-internal"].name
    }
  }

  linux_virtual_machines = {
    "vm-linux-1" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name = "vm-linux-1"
      size = local.vm_image["linux_vm"].vm_size

      disable_password_authentication = "false"

      admin_username = local.username
      admin_password = local.password

      network_interface_ids = [azurerm_network_interface.network_interface["nic-linux-1-eth1"].id]

      identity_type = "SystemAssigned"

      os_disk_name                 = "osdisk-vm-linux-1"
      os_disk_caching              = "ReadWrite"
      os_disk_storage_account_type = "Standard_LRS"

      source_image_reference_publisher = local.vm_image["linux_vm"].publisher
      source_image_reference_offer     = local.vm_image["linux_vm"].offer
      source_image_reference_version   = local.vm_image["linux_vm"].version
      source_image_reference_sku       = local.vm_image["linux_vm"].sku

      identity_type = "SystemAssigned"

      tags_ComputeType = "unknown"
    }
    "vm-linux-2" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name = "vm-linux-2"
      size = local.vm_image["linux_vm"].vm_size

      disable_password_authentication = "false"

      admin_username = local.username
      admin_password = local.password

      network_interface_ids = [azurerm_network_interface.network_interface["nic-linux-2-eth1"].id]

      identity_type = "SystemAssigned"

      os_disk_name                 = "osdisk-vm-linux-2"
      os_disk_caching              = "ReadWrite"
      os_disk_storage_account_type = "Standard_LRS"

      source_image_reference_publisher = local.vm_image["linux_vm"].publisher
      source_image_reference_offer     = local.vm_image["linux_vm"].offer
      source_image_reference_version   = local.vm_image["linux_vm"].version
      source_image_reference_sku       = local.vm_image["linux_vm"].sku

      tags_ComputeType = "WebServer"
    }
  }

  virtual_machines = {
    "vm-fgt" = {
      resource_group_name = local.resource_group_name
      location            = local.location

      name    = "vm-fgt"
      vm_size = local.vm_image["fortigate"].vm_size

      network_interface_ids        = [azurerm_network_interface.network_interface["nic-fgt-port1"].id, azurerm_network_interface.network_interface["nic-fgt-port2"].id]
      primary_network_interface_id = azurerm_network_interface.network_interface["nic-fgt-port1"].id

      delete_os_disk_on_termination    = true
      delete_data_disks_on_termination = true

      identity_type = "SystemAssigned"

      storage_image_reference_publisher = local.vm_image["fortigate"].publisher
      storage_image_reference_offer     = local.vm_image["fortigate"].offer
      storage_image_reference_sku       = local.vm_image["fortigate"].sku
      storage_image_reference_version   = local.vm_image["fortigate"].version

      plan_name      = local.vm_image["fortigate"].sku
      plan_publisher = local.vm_image["fortigate"].publisher
      plan_product   = local.vm_image["fortigate"].offer

      storage_os_disk_name              = "osdisk-vm-fgt-os"
      storage_os_disk_caching           = "ReadWrite"
      storage_os_disk_create_option     = "FromImage"
      storage_os_disk_managed_disk_type = "Standard_LRS"

      storage_data_disk_name              = "disk-vm-fgt-data"
      storage_data_disk_create_option     = "Empty"
      storage_data_disk_disk_size_gb      = "30"
      storage_data_disk_lun               = 0
      storage_data_disk_managed_disk_type = "Standard_LRS"

      os_profile_admin_username           = local.username
      os_profile_admin_password           = local.password
      os_profile_custom_data              = "fgtvm.conf"
      os_profile_custom_data_api_key      = random_string.string.id
      os_profile_custom_data_type         = local.vm_image["fortigate"].sku
      os_profile_custom_data_license_file = ""

      tags_ComputeType = "unknown"
    }
  }

  role_assignments = {
    "vm-fgt" = {
      scope                = local.resource_group_id
      role_definition_name = "Contributor"
      principal_id         = azurerm_virtual_machine.virtual_machine["vm-fgt"].identity[0].principal_id
    }
    format("aa-%s", local.username) = {
      scope                = local.resource_group_id
      role_definition_name = "Contributor"
      principal_id         = azurerm_automation_account.automation_account[format("aa-%s", local.username)].identity[0].principal_id
    }
  }

  network_interface_security_group_associations = {
    "nic-fgt-port1" = {
      network_interface_id      = azurerm_network_interface.network_interface["nic-fgt-port1"].id
      network_security_group_id = azurerm_network_security_group.network_security_group["nsg-external"].id
    }
    "nic-fgt-port2" = {
      network_interface_id      = azurerm_network_interface.network_interface["nic-fgt-port2"].id
      network_security_group_id = azurerm_network_security_group.network_security_group["nsg-internal"].id
    }
  }
}