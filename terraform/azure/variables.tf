variable "username" {
  default = ""
  type    = string
}

variable "enable_output" {
  default = true
  type    = bool
}

variable "usertags" {
  default = {}
  type    = map(string)
}