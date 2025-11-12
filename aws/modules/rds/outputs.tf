output "mysql-admin-password" {
  value = random_password.mysql-admin-password.result
}

output "mysql-endpoint" {
  value = aws_db_instance.rds-mysql-instance.endpoint
}