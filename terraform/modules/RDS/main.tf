# Create a PostgreSQL RDS instance
resource "aws_db_instance" "postgres_db_django" {
  allocated_storage      = var.allocated_storage
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = "postgresDB"
  username               = "postgresadmin"
  password               = "Admin123!"
  skip_final_snapshot    = true
  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_grp.name
  multi_az               = true
  publicly_accessible    = false
  storage_type           = "gp2"
  
  tags = {
    Name = "Django-PostgresDB"
    Environment = var.environment
  }
  
  lifecycle {
    replace_triggered_by = [aws_db_subnet_group.rds_subnet_grp]
  }
}


# Create subnet group for database
resource "aws_db_subnet_group" "rds_subnet_grp" {
    name       = "django-app-db-subnet-grp-${random_string.suffix.result}"
    subnet_ids = var.database_subnet_ids

    tags = {
      Name = "Django-App-Database-Subnet-Group"
    }
    
    lifecycle {
      create_before_destroy = true
    }
}

# Generate random suffix to avoid naming conflicts
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}



# Store the RDS endpoint in Parameter Store
resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "/DjangoApp/rds_endpoint"
  type  = "String"
  value = aws_db_instance.postgres_db_django.endpoint
}