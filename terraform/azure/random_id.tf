resource "random_id" "id" {
  keepers = {
    resource_group = local.resource_group_name
  }

  byte_length = 4
}
