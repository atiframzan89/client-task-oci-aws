resource "aws_security_group" "rds-sg" {
  name        = "${var.customer}-mysql-sg-${var.environment}"
  description = "Allow MySQL inbound traffic"
  vpc_id      = var.vpc-id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Not for production!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
      "Name"          = "${var.customer}-rds-sg-${var.environment}"
      "Environment"   = var.environment
      "Customer"      = var.customer
      "Terraform"     = "True"
  }
}

resource "random_password" "mysql-admin-password" {
  length           = 10  # Use a good length, OCI min is 8
  special          = false
#   override_special = "!@#-_" # OCI only allows _, #, or - (I've added ! and @ for strength, but be careful)
  numeric          = true
  upper            = true
  lower            = true
}

# --- RDS Instance ---
resource "aws_db_instance" "rds-mysql-instance" {
  identifier     = "${var.customer}-mysql-${var.environment}"
  engine         = "mysql"
#   engine_version = "8.0.35"
  db_name        = "${var.customer}_${var.environment}"
  username = var.mysql-admin-user
  password = random_password.mysql-admin-password.result
  instance_class                = "db.t3.micro"
  storage_type                  = "gp2"        
  allocated_storage             = 20
  multi_az                      = false 
  db_subnet_group_name          = var.db-subnet-group
  vpc_security_group_ids        = [aws_security_group.rds-sg.id]
  publicly_accessible           = false 
  backup_retention_period       = 0 
  skip_final_snapshot           = true
  tags = {
      "Name"          = "${var.customer}-rds-sg-${var.environment}"
      "Environment"   = var.environment
      "Customer"      = var.customer
      "Terraform"     = "True"
  } 
}