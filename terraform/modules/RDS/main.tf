resource "aws_db_instance" "postgres_db" {
  allocated_storage    = var.allocated_storage
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_name              = var.db_name
  username             = var.username
  password             = var.password
  parameter_group_name = var.parameter_group_name
  skip_final_snapshot  = true
  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  multi_az              = false
  publicly_accessible   = false
  storage_type          = "gp2"
  tags = {
    Name = "PostgresDB"
    Environment = var.environment
  }
  
}

resource "aws_db_subnet_group" "rds_subnet_grp" {
    name       = "subnet-grp-rds"  # Name of the subnet group
    subnet_ids = [var.private_subnet_3_id, var.private_subnet_4_id]  # Subnets for the RDS instance

    tags = {
      Name = "DigitalBoost-WordPress-RDS-Subnet-Group"  # Updated to reflect the firm's name
    }
}