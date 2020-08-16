variable "service" {
  type    = string
  default = "uestop"
}

variable "layer" {
  type    = string
}

variable "protocol" {
  description = "the protocol for this security groupg"
  type    = string
  default = "tcp"
}

variable "port" {
  description = "define the inbound port and outbound port"
  type = object({
    from  = number
    to    = number
  })
}

variable "name" {
  description = "define a name for this security group"
  type        = string
}

variable "cidr_addresses" {
  type    = list(string)
  default = [ "0.0.0.0/0" ] // default all
}
