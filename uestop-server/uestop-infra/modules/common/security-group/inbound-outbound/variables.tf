variable "service" {
  type    = string
  default = "uestop"
}

variable "layer" {
  type    = string
}

variable "inbound_protocol" {
  description = "inbound protocol for this security group"
  type    = string
  default = "tcp"
}

variable "outbound_protocol" {
  description = "outbound protocol for this security group"
  type    = string
  default = "tcp"
}

variable "inbound_port" {
  description = "defines from and to for inbound port"
  type = object({
    from  = number
    to    = number
  })
}

variable "outbound_port" {
  description = "defines from and to for outbound port"
  type = object({
    from  = number
    to    = number
  })
}

variable "inbound_cidr_addresses" {
  type    = list(string)
  default = [ "0.0.0.0/0" ] // default all
}

variable "outbound_cidr_addresses" {
  type    = list(string)
  default = [ "0.0.0.0/0" ] // default all
}

variable "name" {
  description = "define a name for this security group"
  type        = string
}
