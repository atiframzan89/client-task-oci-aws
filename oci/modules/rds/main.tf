resource "random_password" "mysql-admin-password" {
  length           = 16  # Use a good length, OCI min is 8
  special          = true
  override_special = "!@#-_" # OCI only allows _, #, or - (I've added ! and @ for strength, but be careful)
  numeric          = true
  upper            = true
  lower            = true
}

resource "oci_mysql_mysql_db_system" "mysql-db-system" {
  # Required arguments
  availability_domain = var.ad
  compartment_id      = var.compartment-ocid
  shape_name          = "MySQL.VM.Standard.E3.1.8GB"
  subnet_id           = var.private-subnet-id # Reference to your pre-existing or created subnet
  
  
  
#   nsg_ids = [ local.nsg-id ]
  # Admin User Configuration
  admin_username = "adminuser"
  admin_password = random_password.mysql-admin-password.result

  # Optional arguments for configuration
  display_name = "${var.customer}-mysql-${var.environment}"
#   description  = "A test MySQL DB System deployed with Terraform"
  
}

# resource "oci_core_default_security_list" "default_security_list" {
#   manage_default_resource_id = oci_core_vcn.spoke01.default_security_list_id

#   # Allow all ingress from within the VCN CIDR
#   ingress_security_rules {
#     protocol    = "all"
#     source      = oci_core_vcn.spoke01.cidr_block
#     source_type = "CIDR_BLOCK"
#     description = "Allow all inbound traffic within VCN"
#   }

#   # Allow all egress to anywhere (optional)
#   egress_security_rules {
#     protocol         = "all"
#     destination      = "0.0.0.0/0"
#     destination_type = "CIDR_BLOCK"
#     description      = "Allow all outbound traffic"
#   }
# }
