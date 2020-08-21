module "instance" {
  source = "../instance"
}

## Defines how the ASG will launch new instances
resource "aws_launch_configuration" "webserver-launch-config" {
  image_id        = module.instance.ami
  instance_type   = module.instance.type
  security_groups = var.security_groups

  user_data = var.user_data

  // this allows the ASG to point to the new launch configuration resource before deleting the current version.
  // it's not possible to delete the current without changing the pointers while this is being used by the ASG.
  lifecycle {
    create_before_destroy = true
  }
}

## creates the ASG
resource "aws_autoscaling_group" "webserver-asg" {
  launch_configuration  = aws_launch_configuration.webserver-launch-config.name
  vpc_zone_identifier   = module.instance.subnet-ids

  target_group_arns = var.target_group_arns
  health_check_type = "ELB"

  min_size = 2
  max_size = 4
}
