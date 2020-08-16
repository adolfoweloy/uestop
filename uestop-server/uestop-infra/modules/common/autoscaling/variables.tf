variable "security_groups" {
  description = "security groups to be attached to launch configuration"
  type        = list(string)
}

variable "user_data" {
  type = string
}

variable "target_group_arns" {
  description = "arns of the target groups to attach to this autoscaling group"
  type = list(string)
}