output "vpc-id" {
  value = aws_vpc.customer-vpc.id
}

output "public-subnet-1" {
  value = aws_subnet.public_subnet[0].id
  
}

output "public-subnet-2" {
  value = aws_subnet.public_subnet[1].id
  
}

output "private-subnet-1" {
  value = aws_subnet.private_subnet[0].id
  
}

output "private-subnet-2" {
  value = aws_subnet.private_subnet[1].id
  
}

output "private-subnet-3" {
  value = aws_subnet.private_subnet[2].id
  
}

output "customer-subnet-group" {
  value = aws_db_subnet_group.customer-subnet-group.id
}

output "internet-gateway-id" {
  value = aws_nat_gateway.customer-nat-gw.id
}

output "private-rt" {
  value = aws_route_table.private_rt_1.id
}

output "db-subnet-group" {
  value = aws_db_subnet_group.customer-subnet-group.id
}

output "bastion-public-ip" {
  value = aws_instance.customer-bastion.public_ip
}
