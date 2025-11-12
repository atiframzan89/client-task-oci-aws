module "vcn" {
    source                  = "./modules/vcn"
    compartment-ocid        = var.compartment-ocid
    environment             = var.environment
    region                  = var.region
    customer                = var.customer
    ssh-public-key          = var.ssh-public-key
    oke-cluster-id          = module.oke.oke-cluster-id
    # vpc                     = var.vpc
    # az                      = data.aws_availability_zones.available.names
    # environment             = var.environment
    # customer                = var.customer

}

module "oke" {
    source                  = "./modules/oke"
    region                  = var.region
    user-ocid               = var.user-ocid
    compartment-ocid        = var.compartment-ocid
    environment             = var.environment
    customer                = var.customer
    tenancy-ocid            = var.tenancy-ocid
    vcn-id                  = module.vcn.vcn-id
    private-subnet-id       = module.vcn.private-subnet-id
    public-subnet-id        = module.vcn.public-subnet-id
    # availability-domain     = data.oci_identity_availability_domains.ads.availability_domains[0].name
      
    }

module "rds" {
    source                  = "./modules/rds"
    ad                      = data.oci_identity_availability_domains.ads.availability_domains[0].name
    compartment-ocid        = var.compartment-ocid
    environment             = var.environment
    customer                = var.customer
    vcn-id                  = module.vcn.vcn-id
    private-subnet-id       = module.vcn.private-subnet-id
}