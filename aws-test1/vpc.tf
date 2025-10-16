resource "aws_vpc" "vpcM" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name        = "vpcM"
    project     = "Mtest"
    environment = "production"
    module      = "vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.vpcM_subnet_cidr_public)
  vpc_id            = aws_vpc.vpcM.id
  cidr_block        = element(var.vpcM_subnet_cidr_public, count.index)
  availability_zone = element(var.vpcM_azs, count.index)

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.vpcM_subnet_cidr_private)
  vpc_id            = aws_vpc.vpcM.id
  cidr_block        = element(var.vpcM_subnet_cidr_private, count.index)
  availability_zone = element(var.vpcM_azs, count.index)

  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igwM" {
  vpc_id = aws_vpc.vpcM.id

  tags = {
    Name = "vpcM Internet Gateway"
  }
}

resource "aws_route_table" "rt_vpcM_igw" {
  vpc_id = aws_vpc.vpcM.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igwM.id
  }

  tags = {
    Name = "IGW Route Table"
  }
}

resource "aws_route_table_association" "rt_vpcM_pubsub_igw" {
  count          = length(var.vpcM_subnet_cidr_public)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.rt_vpcM_igw.id
}

resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.igwM]
  domain     = "vpc"
  tags = {
    Name = "EIP for NAT"
  }
}

resource "aws_nat_gateway" "nat_private" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[1].id

  tags = {
    Name = "vpcM private NAT"
  }

  depends_on = [aws_internet_gateway.igwM]
}

resource "aws_route_table" "rt_vpcM_nat_pri" {
  vpc_id = aws_vpc.vpcM.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_private.id
  }
}

resource "aws_route_table_association" "rt_vpcM_pri" {
  count          = length(var.vpcM_subnet_cidr_private)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.rt_vpcM_nat_pri.id
}

resource "aws_vpc_endpoint" "vpcM_SSMH" {
  vpc_id              = aws_vpc.vpcM.id
  service_name        = "com.amazonaws.ap-southeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  route_table_ids     = [aws_route_table.rt_vpcM_nat_pri.id]
  security_group_ids  = [aws_security_group.ecs_pub_ssmhost_1_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "SSM host ec2"
  }
}     