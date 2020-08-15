variable "webserver-admin-port" {
  description = "Webserver ssh port for admin purposes"
  type        = number
  default     = 22
}

variable "layer" {
  description = "defines the layer of a resource such as (web, admin, worker, db)"
  type        = string
}

variable "service" {
  description = "service name"
  type        = string
  default     = "uestop"
}