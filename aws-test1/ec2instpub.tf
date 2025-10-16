resource "aws_instance" "pub_ssmhost_1" {
  ami                = "ami-0ffd8e96d1336b6ac"
  instance_type      = "t3.micro"
  ipv6_address_count = "0"

  maintenance_options {
    auto_recovery = "default"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = "2"
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }

  monitoring                 = "false"
  placement_partition_number = "0"

  private_dns_name_options {
    enable_resource_name_dns_a_record    = "false"
    enable_resource_name_dns_aaaa_record = "false"
    hostname_type                        = "ip-name"
  }

  root_block_device {
    delete_on_termination = "true"
    encrypted             = "false"
    iops                  = "3000"

    tags = {
      Name        = "pub_ssmhost_1_OS"
      environment = "production"
      module      = "ebs"
      project     = "Mtest"
    }

    tags_all = {
      Name        = "pub_ssmhost_1_OS"
      environment = "production"
      module      = "ebs"
      project     = "Mtest"
    }

    throughput  = "125"
    volume_size = "50"
    volume_type = "gp3"
  }

  source_dest_check           = "true"
  subnet_id                   = aws_subnet.public_subnets[1].id
  user_data_replace_on_change = "false"
  vpc_security_group_ids      = [aws_security_group.ecs_pub_ssmhost_1_sg.id]

  tags = {
    Name        = "pub_ssmhost_1"
    project     = "Mtest"
    environment = "production"
    module      = "ec2"
  }
}

resource "aws_security_group" "ecs_pub_ssmhost_1_sg" {
  name        = "ecs_pub_ssmhost_1_sg"
  description = "ecs_pub_ssmhost_1_sg"
  vpc_id      = aws_vpc.vpcM.id

  ingress {
    cidr_blocks = [aws_vpc.vpcM.cidr_block]
    description = "public http"
    from_port   = "80"
    protocol    = "tcp"
    self        = "false"
    to_port     = "80"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "ssm maria"
    from_port   = "3306"
    protocol    = "tcp"
    self        = "false"
    to_port     = "3306"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "ssm ssh"
    from_port   = "22"
    protocol    = "tcp"
    self        = "false"
    to_port     = "22"
  }
}