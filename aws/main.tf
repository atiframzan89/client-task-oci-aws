module "vpc" {
    source                  = "./modules/vpc"
    vpc                     = var.vpc
    az                      = data.aws_availability_zones.available.names
    environment             = var.environment
    customer                = var.customer
    keypair                = var.keypair
    amazon-linux-ami        = data.aws_ami.amazon-linux-2

}

module "rds" {
    source                  = "./modules/rds"
    environment             = var.environment
    vpc-id                  = module.vpc.vpc-id
    customer                = var.customer
    mysql-admin-user        = var.mysql-admin-user
    db-subnet-group         = module.vpc.db-subnet-group
    # az                      = data.aws_availability_zones.available.names
}
