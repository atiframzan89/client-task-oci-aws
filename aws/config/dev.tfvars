region = "us-east-1"
vpc = {
    #name = "vpc"
    cidr                    = "13.20.0.0/16"
    public_subnet           = ["13.20.1.0/24", "13.20.2.0/24", "13.20.3.0/24" ]
    private_subnet          = ["13.20.4.0/24", "13.20.5.0/24", "13.20.6.0/24" ]
}
customer                    = "console"
environment                 = "dev"
# db-instance-size            = "db.t3.medium"
keypair                     = "citnow-dev-us-east-1"
profile                     = "default"
# aws-account-id              = "741448961150"
mysql-admin-user            = "admin"