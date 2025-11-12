output "mysql-admin-password" {
  value = random_password.mysql-admin-password.result
}

output "mysql-db-ip" {
  value = oci_mysql_mysql_db_system.mysql-db-system.endpoints
}