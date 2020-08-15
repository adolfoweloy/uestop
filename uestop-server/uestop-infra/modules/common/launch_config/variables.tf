variable "port" {
  description = "launch configuration will be used to launch instances listening to the same port which needs to be defined here"
  type        = number
}

variable "name" {
  description = "define a name for this launch configuration"
  type = string
}

variable "layer" {
  description = "define a layer"
  type = string
}