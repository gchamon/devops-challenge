resource "aws_ecs_cluster" "default" {
  name = "${var.environment_name}-cluster"
  tags = {
    Name = "${var.environment_name}-cluster"
  }
}

data "aws_ami" "amazon_linux_ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_launch_template" "ecs" {
  name_prefix   = var.environment_name
  image_id      = data.aws_ami.amazon_linux_ecs.id
  instance_type = var.ecs_instance_type
  key_name      = module.key_pair_ecs_cluster.key_pair.key_name

  iam_instance_profile {
    name = module.iam_role_ecs_agent.role.name
  }

  user_data = base64encode(templatefile(
    "${path.module}/configs/ecs/user_data.sh",
    {
      cluster_name = aws_ecs_cluster.default.name
    }
  ))

  vpc_security_group_ids = [aws_security_group.ecs.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.environment_name}-ecs-asg"
  desired_capacity    = var.ecs_autoscaling_capacity.desired
  min_size            = var.ecs_autoscaling_capacity.min
  max_size            = var.ecs_autoscaling_capacity.max
  vpc_zone_identifier = data.terraform_remote_state.shared.outputs.network.subnets[var.environment_name].*.id

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ecs.id
        version            = "$Latest"
      }

      override {
        instance_type = var.ecs_instance_type
      }
    }

    instances_distribution {
      spot_allocation_strategy                 = "lowest-price"
      on_demand_base_capacity                  = var.ecs_on_demand_base_capacity
      on_demand_percentage_above_base_capacity = 0
    }
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.environment_name}-ecs-asg"
      propagate_at_launch = true
    },
    {
      key                 = "environment"
      value               = var.environment_name
      propagate_at_launch = true
    }
  ]
}

# required permissions for the ECS Agent.
module "iam_role_ecs_agent" {
  source = "../iam_role"

  name     = replace(title("${var.environment_name} ECSAgent"), " ", "")
  policies_arn = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
}
