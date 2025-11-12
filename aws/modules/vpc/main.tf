resource "aws_vpc" "customer-vpc" {
    # name              = var.customer
    cidr_block        = var.vpc.cidr
    tags = {
      "Name"          = "${var.customer}-${var.environment}"
      "Customer"      = var.customer
      "Environment"   = var.environment
      "Terraform"     = "True"
    }
    
}

resource "aws_subnet" "public_subnet" {
    count               = length(var.vpc.public_subnet)
    vpc_id              = aws_vpc.customer-vpc.id
    cidr_block          = element(var.vpc.public_subnet, count.index)
    availability_zone   = element(var.az, count.index)
    depends_on          = [ aws_vpc.customer-vpc, aws_route_table.public_rt_1  ]
    # For sequent Project As per Client Requiremnts
    map_public_ip_on_launch = true

    
    tags = {
      "Name"                            = "${var.customer}-public-subnet-${count.index}"
      "Environment"                     = var.environment
      "Customer"                        = var.customer
      "Terraform"                       = "True"
    }
}

resource "aws_subnet" "private_subnet" {
    count               = length(var.vpc.private_subnet)
    vpc_id              = aws_vpc.customer-vpc.id
    cidr_block          = element(var.vpc.private_subnet, count.index)
    availability_zone   = element(var.az, count.index)
    depends_on          = [ aws_vpc.customer-vpc,
                            aws_route_table.private_rt_1 ]

    
    tags = {
      "Name"                            = "${var.customer}-private-subnet-${count.index}"
      "Environment"                     = var.environment
      "Customer"                        = var.customer
      "Terraform"                       = "True"
    }
}

resource "aws_internet_gateway" "customer-igw" {
    vpc_id        = aws_vpc.customer-vpc.id
    tags          = {
                      "Name"          = "${var.customer}-igw-${var.environment}"
                      "Environment"   = var.environment
                      "Customer"      = var.customer
                      "Terraform"     = "True"
                    }
 
}


resource "aws_route_table" "private_rt_1" {
    vpc_id        = aws_vpc.customer-vpc.id
    depends_on    = [ aws_nat_gateway.customer-nat-gw ]
    route {
      cidr_block  = "0.0.0.0/0"
      nat_gateway_id  = aws_nat_gateway.customer-nat-gw.id 
    }
    tags = {
      "Name"          = "${var.customer}-private-rt-${var.environment}-1"
      "Environment"   = var.environment
      "Customer"      = var.customer
      "Terraform"     = "True"

    }
}

resource "aws_route_table" "public_rt_1" {
    vpc_id        = aws_vpc.customer-vpc.id
    depends_on    = [ aws_internet_gateway.customer-igw ]
    route {
      cidr_block  = "0.0.0.0/0"
      gateway_id  = aws_internet_gateway.customer-igw.id
     } 
    tags = {
      "Name"          = "${var.customer}-public-rt-${var.environment}-1"
      "Environment"   = var.environment
      "Customer"      = var.customer
      "Terraform"     = "True"

    }
}

resource "aws_route_table_association" "public_rt_1_association" {
  count               = length(var.vpc.public_subnet)
  subnet_id           = aws_subnet.public_subnet[count.index].id
  route_table_id      = aws_route_table.public_rt_1.id
}

resource "aws_route_table_association" "private_rt_1_association" {
  count               = length(var.vpc.private_subnet)
  subnet_id           = aws_subnet.private_subnet[count.index].id
  route_table_id      = aws_route_table.private_rt_1.id
}

resource "aws_nat_gateway" "customer-nat-gw" {
  allocation_id       = aws_eip.customer-eip.id
  subnet_id           = aws_subnet.public_subnet[0].id
  depends_on          = [ aws_internet_gateway.customer-igw, aws_eip.customer-eip ]
  tags = {
    "Name"          = "${var.customer}-igw-${var.environment}"
    "Environment"   = var.environment
    "Customer"      = var.customer
    "Terraform"     = "True"
  }
  
}

resource "aws_eip" "customer-eip" {
  # vpc = true
    tags = {
      "Name"          = "${var.customer}-eip-${var.environment}"
      "Environment"   = var.environment
      "Customer"      = var.customer
      "Terraform"     = "True"
    }
  
}

resource "aws_db_subnet_group" "customer-subnet-group" {
  name       = "${var.customer}-subnet-group-${var.environment}"
  subnet_ids = [ aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id ]

  tags = {
      "Name"          = "${var.customer}-subnet-group-${var.environment}"
      "Environment"   = var.environment
      "Customer"      = var.customer
      "Terraform"     = "True"
  }
}

data "template_file" "userdata" {
  template = file("${path.module}/templates/userdata.sh")
}


# Bastion EC2 Creation
resource "aws_instance" "customer-bastion" {
 ami                                    = var.amazon-linux-ami.id
 associate_public_ip_address            = true
#  iam_instance_profile                   = "${aws_iam_instance_profile.test.id}"
 instance_type                          = "t2.micro"
 key_name                               = var.keypair
#  vpc_security_group_ids                 = ["${aws_security_group.test.id}"]
 security_groups                        = [ aws_security_group.ec2-sg.id ]
 subnet_id                              = aws_subnet.public_subnet[0].id
 user_data                              = data.template_file.userdata.rendered
 lifecycle {
   ignore_changes = [ security_groups ]
 }
 tags = {
    "Name"            = "${var.customer}-bastion-${var.environment}"
    "Customer"        = var.customer
    "Environment"     = "${var.environment}"
    "Terraform"       = "True"

  }
}


resource "aws_security_group" "ec2-sg" {
  name        = "${var.customer}-bastion-${var.environment}-sg"
  description = "${var.customer}-bastion-${var.environment}-sg"
  vpc_id      = aws_vpc.customer-vpc.id

  ingress {
    description = "Allow SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    # security_groups = [ var.eks-node-group-sg ]
    cidr_blocks = ["0.0.0.0/0"]
    # source_security_group_id = var.eks-node-group-sg
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags = {
    "Name"            = "${var.customer}-bastion-${var.environment}-sg"
    "Customer"        = var.customer
    "Environment"     = "${var.environment}"
    "Terraform"       = "True"

  }

}

# Virtual Private Gateway
resource "aws_vpn_gateway" "customer-vgw" {
  vpc_id = aws_vpc.customer-vpc.id

  tags = {
    "Name"            = "${var.customer}-vgw-${var.environment}"
    "Customer"        = var.customer
    "Environment"     = "${var.environment}"
    "Terraform"       = "True"
  }
}

# Customer Gateway 
# For OCI BGP ASN: 31898
resource "aws_customer_gateway" "oci-cgw" {
  # This is the public IP of your OCI VPN endpoint
  ip_address = "1.1.1.1"

  # This is the BGP ASN for your OCI VPN
  bgp_asn    = "31898"

  # This type is required for BGP-based IPSec tunnels
  type       = "ipsec.1"

  tags = {
    "Name"            = "${var.customer}-customer-gw-${var.environment}"
    "Customer"        = var.customer
    "Environment"     = "${var.environment}"
    "Terraform"       = "True"
  }
}

# AWS Site-To-Site VPN Connection
resource "aws_vpn_connection" "aws-to-oci-vpn" {
  vpn_gateway_id      = aws_vpn_gateway.customer-vgw.id
  customer_gateway_id = aws_customer_gateway.oci-cgw.id
  type                = "ipsec.1"

  # This is the key argument for your static routing plan.
  # It disables BGP.
  static_routes_only = true

  tags = {
    "Name"            = "${var.customer}-aws-to-oci-vpn-${var.environment}"
    "Customer"        = var.customer
    "Environment"     = "${var.environment}"
    "Terraform"       = "True"
  }
}

resource "aws_vpn_connection_route" "oci-route" {
  destination_cidr_block = "10.0.0.0/16"
  vpn_connection_id      = aws_vpn_connection.aws-to-oci-vpn.id
}