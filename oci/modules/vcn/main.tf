resource "oci_core_vcn" "customer-vcn" {
  cidr_block            = "10.0.0.0/16"
  dns_label             = "hub"
  compartment_id        = var.compartment-ocid
  display_name          = "${var.customer}-vcn-${var.environment}"

}

resource "oci_core_internet_gateway" "internet-gateway" {
  compartment_id        = var.compartment-ocid
  vcn_id                = oci_core_vcn.customer-vcn.id
  enabled               = "true"
  display_name          = "${var.customer}-igw-${var.environment}"
#   defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_nat_gateway" "nat-gateway" {
  compartment_id        = var.compartment-ocid
  vcn_id                = oci_core_vcn.customer-vcn.id
  display_name          = "${var.customer}-nat-gw-${var.environment}"
}

# Public route table — routes to Internet Gateway
resource "oci_core_route_table" "public-rt" {
  compartment_id = var.compartment-ocid
  vcn_id         = oci_core_vcn.customer-vcn.id
  display_name   = "${var.customer}-public-rt-1-${var.environment}"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet-gateway.id  
    }
}

resource "oci_core_route_table" "private-rt" {
  compartment_id = var.compartment-ocid
  vcn_id         = oci_core_vcn.customer-vcn.id
  display_name   = "${var.customer}-private-rt-1-${var.environment}"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat-gateway.id
  }
}

# Public Subnet

# Public Subnet — can reach Internet via IGW
resource "oci_core_subnet" "public-subnet" {
  compartment_id             = var.compartment-ocid
  vcn_id                     = oci_core_vcn.customer-vcn.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "${var.customer}-public-subnet-1-${var.environment}"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public-rt.id
  security_list_ids          = [oci_core_vcn.customer-vcn.default_security_list_id]
  dns_label                  = "public"
}

# Private Subnet — outbound only via NAT
resource "oci_core_subnet" "private-subnet" {
  compartment_id             = var.compartment-ocid
  vcn_id                     = oci_core_vcn.customer-vcn.id
  cidr_block                 = "10.0.3.0/24"
  display_name               = "${var.customer}-private-subnet-1-${var.environment}"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private-rt.id
#   security_list_ids          = [oci_core_vcn.customer-vcn.default_security_list_id]
  security_list_ids          = [oci_core_security_list.private-sl.id]
  dns_label                  = "private"
}

# ─────────────────────────────────────────────
# Security List Definition
# ─────────────────────────────────────────────
resource "oci_core_security_list" "private-sl" {
  compartment_id = var.compartment-ocid
  vcn_id         = oci_core_vcn.customer-vcn.id
  display_name   = "${var.customer}-security-list-${var.environment}"

  # Allow all egress (outbound) traffic
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }
  ingress_security_rules {
    protocol = "6"
    source   = "10.0.0.0/16"
    tcp_options {
            min = 22
            max = 22
        }
    description = "Allow SSH from within the VCN"
    }
  ingress_security_rules {
    protocol = "6"
    source   = "10.0.0.0/16"
    tcp_options {
            min = 3306
            max = 3306
        }
    description = "Allow SSH from within the VCN"
    }
    
    ingress_security_rules {
    protocol    = "all"
    source      = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }
}

resource "oci_core_instance" "public-instance" {
  compartment_id      = var.compartment-ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.customer}-public-instance-${var.environment}"
  shape               = "VM.Standard.E2.1.Micro"
  

  # shape_config {
  #   ocpus         = 1
  #   memory_in_gbs = 8
  # }

  create_vnic_details {
    subnet_id          = oci_core_subnet.public-subnet.id
    assign_public_ip   = true
    # nsg_ids            = [oci_core_network_security_group.hub_nsg.id]
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh-public-key
    # user_data = templatefile("${path.module}/private-intance.sh")
  }
}

resource "oci_core_instance" "private-instance" {
  compartment_id      = var.compartment-ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.customer}-private-instance-${var.environment}"
  shape               = "VM.Standard.E2.1.Micro"

  # shape_config {
  #   ocpus         = 1
  #   memory_in_gbs = 8
  # }

  create_vnic_details {
    subnet_id          = oci_core_subnet.private-subnet.id
    assign_public_ip   = false
    # nsg_ids            = [oci_core_network_security_group.hub_nsg.id]
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh-public-key
    user_data = base64encode(templatefile("${path.module}/templates/private-instance.sh", {
      # This is where we pass variables into the template
      cluster-id = "${var.oke-cluster-id}"
      region     = "${var.region}"
    }))
  }
}

resource "oci_core_network_security_group" "instance-sg" {
  compartment_id = var.compartment-ocid
  vcn_id         = oci_core_vcn.customer-vcn.id
  display_name   = "${var.customer}-instance-sg-${var.environment}"
}

resource "oci_core_network_security_group_security_rule" "egress-all" {
  network_security_group_id = oci_core_network_security_group.instance-sg.id
  direction                 = "EGRESS"
  protocol                  = "all" # Any protocol for flexibility
  stateless                 = false # Must be stateful so return traffic is allowed
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "Allow all outbound traffic"
}

resource "oci_core_network_security_group_security_rule" "ingress-all" {
  network_security_group_id = oci_core_network_security_group.instance-sg.id
  direction = "INGRESS"
  protocol  = "all"
  source    = "0.0.0.0/0"
}
