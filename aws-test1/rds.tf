resource "aws_db_instance" "dbM" {
  instance_class    = "db.t4g.micro"
  storage_type      = "gp3"
  allocated_storage = 30
  engine            = "mariadb"
  engine_version    = "11.8.3"
  username          = "sa"
  password          = "test1234"

  vpc_security_group_ids = [aws_security_group.rds_dbM_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subg.name

  skip_final_snapshot     = true
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "tue:04:00-tue:04:30"
  parameter_group_name    = aws_db_parameter_group.rds_maria11_8.name

  multi_az = true
}

resource "aws_db_subnet_group" "rds_subg" {
  name       = "rds_subg"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_parameter_group" "rds_maria11_8" {
  name   = "rds-maria11.8"
  family = "maria11.8"
}

resource "aws_security_group" "rds_dbM_sg" {
  name        = "rds_dbM_sg"
  description = "rds_dbM_sg_private"
  vpc_id      = aws_vpc.vpcM.id

  ingress {
    cidr_blocks = var.vpcM_subnet_cidr_private
    description = "private subnet"
    from_port   = "3306"
    protocol    = "tcp"
    self        = "false"
    to_port     = "3306"
  }
}

resource "aws_security_group" "rds_dbM_sg_ec2pub" {
  name        = "rds_dbM_sg_ec2pub"
  description = "rds_dbM_sg_ec2pub"
  vpc_id      = aws_vpc.vpcM.id

  ingress {
    cidr_blocks = [aws_instance.pub_ssmhost_1.private_ip]
    description = "public ec2 instance"
    from_port   = "3306"
    protocol    = "tcp"
    self        = "false"
    to_port     = "3306"
  }
}

resource "aws_db_instance" "dbM_replica" {
  instance_class    = "db.t4g.micro"
  storage_type      = "gp3"
  allocated_storage = 30
  engine            = "mariadb"
  engine_version    = "11.8.3"
  username          = "sa"
  password          = "test1234"

  vpc_security_group_ids = [aws_security_group.rds_dbM_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subg.name

  skip_final_snapshot     = true
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "tue:04:00-tue:04:30"
  parameter_group_name    = aws_db_parameter_group.rds_maria11_8.name

  multi_az = true
}