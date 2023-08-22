resource "random_id" "id" {
  keepers = {
    resource_group = local.resource_group_name
  }

  byte_length = 4
}

output "id" {
  value = var.enable_output ? random_id.id.hex : null
}
