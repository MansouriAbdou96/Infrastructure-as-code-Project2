terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"

  backend "s3" {
    bucket = "mytf-infra-bucket"
    key    = "tf-server/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "mytf-infra-bucket"
    key    = "tf-infra/terraform.tfstate"
    region = "us-east-1"
  }

}

resource "aws_iam_instance_profile" "S3AccessIProfile" {
  name = "S3AccessInstanceProfile"
  role = aws_iam_role.S3AccessRole.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [ "sts:AssumeRole" ]

    managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
  }
}

resource "aws_iam_role" "S3AccessRole" {
  name = "S3AccessRole"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_security_group" "LBSecGroup" {
  description = "Allow http to our load balancer"
  vpc_id      = data.terraform_remote_state.network.outputs.VPC

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "WebSerSecGroup" {
  description = "Allow http to our hosts"
  vpc_id      = data.terraform_remote_state.network.outputs.VPC

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "WebAppLaunchConfig" {
  image_id = var.AMItoUse
  # iam_instance_profile = aws_iam_instance_profile.S3AccessIProfile.id
  security_groups = [aws_security_group.WebSerSecGroup.id]
  instance_type   = var.InstanceTypeToUse

  root_block_device {
    volume_type = "gp2"
    volume_size = 10
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install unzip awscli -y
    sudo apt-get install apache2 -y
    sudo systemctl start apache2.service
    sudo echo "<h1>This is for Testing my website</h1>" > /var/www/html/index.html
    sudo systemctl restart apache2.service
  EOF
}

resource "aws_autoscaling_group" "WebAppGroup" {
  vpc_zone_identifier  = [data.terraform_remote_state.network.outputs.PrivateSubnets]
  launch_configuration = aws_launch_configuration.WebAppLaunchConfig.name

  min_size = 2
  max_size = 4

  target_group_arns = [aws_lb_target_group.WebAppTargetGroup.arn]
}

resource "aws_lb" "WebAppLB" {
  subnets = [
    data.terraform_remote_state.network.outputs.PublicSubnet1,
    data.terraform_remote_state.network.outputs.PublicSubnet2
  ]

  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.LBSecGroup.id]
}

resource "aws_lb_listener" "Listener" {
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WebAppTargetGroup.arn
  }
  load_balancer_arn = aws_lb.WebAppLB.arn
  port              = 80
  protocol          = "HTTP"
}

resource "aws_lb_listener_rule" "ALBListenerRule" {
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WebAppTargetGroup.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  listener_arn = aws_lb_listener.Listener.arn
  priority     = 1
}


resource "aws_lb_target_group" "WebAppTargetGroup" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.VPC

  health_check {
    path                = "/"
    protocol            = "HTTP"
    timeout             = 8
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_sns_topic" "SNSAlarmTopic" {
  display_name = "AlarmNotification"
  name         = "AlarmNotifications"
}

resource "aws_sns_topic_subscription" "EmailSubscription" {
  endpoint  = "your_email2@gmail.com"
  protocol  = "email"
  topic_arn = aws_sns_topic.SNSAlarmTopic.arn

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_cloudwatch_metric_alarm" "HighCPUAlarm" {
  alarm_name          = "HighCPUAlarm"
  alarm_description   = "Alarm if CPU utilization is higher then 70%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.SNSAlarmTopic.arn]

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.WebAppGroup.name
  }

  unit = "Percent"
}