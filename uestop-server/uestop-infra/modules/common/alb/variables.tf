variable "name" {
  description = "base name for the Load Balancer + Target Group"
  type        = string
}

variable "app_port" {
  description = "port for your application behind the Load Balancer. e.g. 8080"
  type        = number
}

variable "lb_port" {
  description = "port for your loadbalancer. this is the main interface e.g. 80"
  type        = number
}
