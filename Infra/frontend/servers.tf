


data "aws_ami" "ami" {

  most_recent      = true
  owners           = ["amazon"]
  sort_ascending = true

  filter {
    name   = "name"
    values = ["ubuntu/images/*/ubuntu-*-24.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "server_template" {
  name = "webserver_template"
  instance_type = var.instance_type
  image_id = data.aws_ami.ami.image_ids[0]
  disable_api_termination = true

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      delete_on_termination = true
    }
  }

  user_data = filebase64("${path.module}/example.sh")
}


resource "aws_autoscaling_group" "autoscaling" {
  availability_zones     = var.availability_zones
  desired_capacity       = 2
  max_size               = 3
  min_size               = 2
  health_check_type      = "elb"
  target_group_arns      = var.target_group_arns
  vpc_zone_identifier    = var.subnets_ids
  termination_policies   = "OldestInstance"
  launch_template {
    id      = aws_launch_template.server_template.id
  }
}