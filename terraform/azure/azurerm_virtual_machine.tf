resource "azurerm_virtual_machine" "virtual_machine" {
  for_each = local.virtual_machines

  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  name = each.value.name

  network_interface_ids        = each.value.network_interface_ids
  primary_network_interface_id = each.value.primary_network_interface_id
  vm_size                      = each.value.vm_size

  delete_os_disk_on_termination    = each.value.delete_os_disk_on_termination
  delete_data_disks_on_termination = each.value.delete_data_disks_on_termination

  identity {
    type = each.value.identity_type
  }

  storage_image_reference {
    publisher = each.value.storage_image_reference_publisher
    offer     = each.value.storage_image_reference_offer
    sku       = each.value.storage_image_reference_sku
    version   = each.value.storage_image_reference_version
  }

  plan {
    name      = each.value.plan_name
    publisher = each.value.plan_publisher
    product   = each.value.plan_product
  }

  storage_os_disk {
    name              = each.value.storage_os_disk_name
    caching           = each.value.storage_os_disk_caching
    create_option     = each.value.storage_os_disk_create_option
    managed_disk_type = each.value.storage_os_disk_managed_disk_type
  }

  # Log data disks
  storage_data_disk {
    name              = each.value.storage_data_disk_name
    create_option     = each.value.storage_data_disk_create_option
    disk_size_gb      = each.value.storage_data_disk_disk_size_gb
    lun               = each.value.storage_data_disk_lun
    managed_disk_type = each.value.storage_data_disk_managed_disk_type
  }

  os_profile {
    computer_name  = each.value.name
    admin_username = each.value.os_profile_admin_username
    admin_password = each.value.os_profile_admin_password
    custom_data = templatefile("${each.value.os_profile_custom_data}", {
      hostname      = each.value.name
      api_key       = each.value.os_profile_custom_data_api_key
      license_type  = each.value.os_profile_custom_data_license_type
      license_file  = each.value.os_profile_custom_data_license_file
      license_token = each.value.os_profile_custom_data_license_token
    })
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = ""
  }
}

output "virtual_machines" {
  value = var.enable_output ? azurerm_virtual_machine.virtual_machine[*] : null
  sensitive = true
}
