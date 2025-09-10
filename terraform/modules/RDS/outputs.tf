output "rds_endpoint" {
  value = aws_db_instance.postgres_db_django.endpoint
}

output "rds_id" {
  value = aws_db_instance.postgres_db_django.id
}