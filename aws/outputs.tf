output "bastion-public-ip" {
  value = module.vpc.bastion-public-ip
}
output "mysql-admin-password" {
  value = module.rds.mysql-admin-password
  sensitive = true
}

output "mysql-endpoint" {
  value = module.rds.mysql-endpoint
}