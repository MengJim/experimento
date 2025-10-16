resource "aws_lb" "lbM-pub2pri-app-1" {
  name               = "lbM-pub2pri-app-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-lbM-pub2pri-app-1.id]
  subnets            = var.vpcM_subnet_cidr_public
  depends_on         = [aws_internet_gateway.igwM]
}

resource "aws_lb_target_group" "lbtg-lbM-pub2pri-app-1" {
  name     = "lbtg-lbM-pub2pri-app-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpcM.id
}

resource "aws_lb_listener" "lblstn-lbM-pub2pri-app-1" {
  load_balancer_arn = aws_lb.lbM-pub2pri-app-1.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbtg-lbM-pub2pri-app-1.arn
  }
}

resource "aws_security_group" "sg-lbM-pub2pri-app-1" {
  name        = "secg-lbM-pub2pri-app-1"
  description = "secg-lbM-pub2pri-app-1"
  vpc_id      = aws_vpc.vpcM.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "public http"
    from_port   = "80"
    protocol    = "tcp"
    self        = "false"
    to_port     = "80"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "public https"
    from_port   = "443"
    protocol    = "tcp"
    self        = "false"
    to_port     = "443"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }
}

resource "aws_launch_template" "lt-asg-app-1" {
  name_prefix   = "lt-asg-app-1"
  image_id      = "ami-0ffd8e96d1336b6ac"
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = aws_subnet.public_subnets[2].id
    security_groups             = [aws_security_group.sg-ec2-app-1.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-1"
    }
  }
}

resource "aws_autoscaling_group" "asg-app-1" {
  desired_capacity = 1
  max_size         = 2
  min_size         = 1

  target_group_arns = [aws_lb_target_group.lbtg-lbM-pub2pri-app-1.arn]

  vpc_zone_identifier = var.vpcM_subnet_cidr_private

  launch_template {
    id      = aws_launch_template.lt-asg-app-1.id
    version = "$Latest"
  }
}

resource "aws_security_group" "sg-ec2-app-1" {
  name        = "secg-ec2-app-1"
  description = "secg-ec2-app-1"
  vpc_id      = aws_vpc.vpcM.id

  ingress {
    description     = "lb http"
    from_port       = "80"
    protocol        = "tcp"
    self            = "false"
    to_port         = "80"
    security_groups = [aws_security_group.sg-lbM-pub2pri-app-1.id]
  }

  ingress {
    cidr_blocks = [aws_instance.pub_ssmhost_1.private_ip]
    description = "public ec2 instance"
    from_port   = "22"
    protocol    = "tcp"
    self        = "false"
    to_port     = "22"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    self        = "false"
    to_port     = "0"
  }
}

resource "aws_autoscaling_policy" "asg-app-1-up" {
  autoscaling_group_name = aws_autoscaling_group.asg-app-1.name
  name                   = "asg-app-1-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
}

resource "aws_autoscaling_policy" "asg-app-1-down" {
  autoscaling_group_name = aws_autoscaling_group.asg-app-1.name
  name                   = "asg-app-1-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cwa-alarm-asg-app-1-up" {
  alarm_name          = "cwa-alarm-asg-app-1-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "70"
  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.asg-app-1.name
  }
  alarm_description = "lb-app-1 hits 70% CPU"
  alarm_actions     = [aws_autoscaling_policy.asg-app-1-up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cwa-alarm-asg-app-1-down" {
  alarm_name          = "cwa-alarm-asg-app-1-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "10"
  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.asg-app-1.name
  }
  alarm_description = "lb-app-1 cools to 10% CPU"
  alarm_actions     = [aws_autoscaling_policy.asg-app-1-down.arn]
}