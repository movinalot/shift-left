variable "username" {
  default = ""
  type    = string
}

variable "password" {
  default = ""
  type    = string
}

variable "enable_output" {
  default = true
  type    = bool
}

variable "tags" {
  default = {}
  type    = map(string)
}