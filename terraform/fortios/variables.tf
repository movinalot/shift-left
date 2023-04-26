
variable "fortigate_ip_or_fqdn" {
  type    = string
  default = ""
}

variable "fortigate_api_token" {
  type    = string
  default = ""
}

variable "resource_group_name" {
  type    = string
  default = ""
}

variable "route_table_name" {
  type    = string
  default = ""
}

variable "next_hop_ip" {
  type    = string
  default = ""
}

variable "webhook" {
  type    = string
  default = ""
}

variable "static_routes" {
  type    = map(any)
  default = {}
}