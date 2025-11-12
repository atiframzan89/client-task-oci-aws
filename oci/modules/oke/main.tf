resource "oci_core_network_security_group" "oke-nsg" {
  compartment_id = var.compartment-ocid
  vcn_id         = var.vcn-id
  display_name   = "${var.customer}-oke-nsg-${var.environment}"
}

# Allow inbound communication from control plane
resource "oci_core_network_security_group_security_rule" "oke-nsg-ingress" {
  network_security_group_id = oci_core_network_security_group.oke-nsg.id
  direction                 = "INGRESS"
  protocol                  = "all"          # Allow all protocols
  source_type               = "CIDR_BLOCK"
  source                    = "0.0.0.0/0"    # Allow from anywhere
  description               = "Allow all inbound traffic"
#   protocol                  = "6" # TCP
#   source_type               = "CIDR_BLOCK"
#   source                    = "0.0.0.0/0"
#   tcp_options {
#     destination_port_range {
#     min = "10250"
#     max = "10255"
#   }
#   }
#   description = "Allow kubelet and control plane communication"
}

# Allow outbound to OCI services and other cluster components
resource "oci_core_network_security_group_security_rule" "oke-nsg-egress" {
  network_security_group_id = oci_core_network_security_group.oke-nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
  description               = "Allow outbound access"
}



# ----------------------------------------------------------
# OKE Cluster (Private)
# ----------------------------------------------------------
resource "oci_containerengine_cluster" "oke_cluster" {
  name             = "${var.customer}-oke-${var.environment}"
  compartment_id   = var.compartment-ocid
  vcn_id           = var.vcn-id                    # From your VCN module output
  kubernetes_version = "v1.31.1"                       # adjust per available version
  
  # Private endpoint config (no public IP)
  endpoint_config {
    is_public_ip_enabled = false
    subnet_id            = var.private-subnet-id   # use private subnet for API endpoint
    nsg_ids              = [ oci_core_network_security_group.oke-nsg.id ]
  }

  # Service LB subnets (can still use public subnets for load balancers if desired)
  options {
    service_lb_subnet_ids = [var.public-subnet-id]
    # open_id_connect_discovery {
    #   is_open_id_connect_discovery_enabled = true
    # }
    
  }

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  # Optional tagging or display info
  freeform_tags = {
    Environment = var.environment
    Customer    = var.customer
  }
}


resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = var.compartment-ocid
  name               = "${var.customer}-oke-nodepool-${var.environment}"
  kubernetes_version = oci_containerengine_cluster.oke_cluster.kubernetes_version
  node_shape         = "VM.Standard.E4.Flex"
  
  node_shape_config {
    ocpus         = 2
    memory_in_gbs = 16
  }

  node_config_details {
    size = 2 
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = var.private-subnet-id 
    }
    node_pool_pod_network_option_details {
    cni_type      = "OCI_VCN_IP_NATIVE"
    pod_subnet_ids = [ var.private-subnet-id ]
  }
  } # <--- **FIX: End the node_config_details block HERE**

  # !! CORRECT LOCATION !!
  # This block is now at the top level, parallel to node_config_details
  

  node_source_details {
    source_type = "image"
    image_id    = "ocid1.image.oc1.me-jeddah-1.aaaaaaaast5tv22nr3phksknow5ovr6ydpyaoaj4uatmaxgl6yno4thhotmq"
  }
}

# Certificate Authority for providers
# resource "oci_certificates_management_ca" "oke-ca" {
#   compartment_id = var.compartment-ocid
#   name           = "${var.customer}-oke-root-ca-${var.environment}"
#   description    = "Root CA for ${var.customer} OKE cluster (${var.environment})"

#   config {
#     config_type = "ROOT_CA_GENERATED_IN_OCI"
#     subject {
#       common_name = "${var.customer}.oke.root.ca"
#     }
#     validity {
#       # 10 years validity
#       time_of_validity_not_after = timeadd(timestamp(), "87600h")
#     }
#   }
# }

# resource "oci_certificates_management_certificate" "oke-ingress-cert" {
#   compartment_id = var.compartment-ocid
#   name           = "${var.customer}-oke-ingress-cert-${var.environment}"

#   certificate_config {
#     config_type = "ISSUED_BY_INTERNAL_CA"
#     issuer_certificate_authority_id = oci_certificates_management_ca.oke-ca.id

#     subject {
#       common_name = "ingress.${var.environment}.${var.customer}.local"
#     }

#     validity {
#       # 1 year
#       time_of_validity_not_after = timeadd(timestamp(), "8760h")
#     }
#   }
# }
# IAM Policy and Dynamic Grouping
data "oci_identity_compartment" "oke_compartment" {
  id = var.compartment-ocid
}

# ---------------------------------------------------------------------------
# Dynamic Group
# ---------------------------------------------------------------------------

# resource "oci_identity_dynamic_group" "oke_worker_nodes_dg" {
#   compartment_id = var.tenancy-ocid
  
#   name           = "oke-worker-nodes-dg"
#   description    = "Dynamic Group for all OKE worker nodes in the cluster compartment."
  
#   matching_rule = "ALL {instance.compartment.id = '${var.compartment-ocid}'}"
# }

# ---------------------------------------------------------------------------
# IAM Policy
# ---------------------------------------------------------------------------

# **CORRECTED RESOURCE TYPE**
# resource "oci_identity_policy" "oke_lb_controller_policy" {
#   compartment_id = var.tenancy-ocid
  
#   name           = "oke-lb-controller-policy"
#   description    = "Grants OKE worker nodes permissions for the OCI LB Controller."

#   # **CORRECTED DYNAMIC GROUP REFERENCE**
#   statements = [
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage load-balancers in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage network-load-balancers in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage network-security-groups in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage security-lists in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to use subnets in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to use vnics in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to use private-ips in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage public-ips in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to inspect vcns in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage certificates-family in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_dg.name} to manage ca-bundles in compartment ${data.oci_identity_compartment.oke_compartment.name}"
#   ]
# }
# Helm for OCI Ingress 

# resource "helm_release" "oci_lb_controller" {
#   name             = "oci-lb-controller"
#   repository       = "https://oracle.github.io/oci-helm-charts"
#   chart            = "oci-native-ingress-controller"
#   namespace        = "oci-lb-controller-system"
#   create_namespace = true

#   set {
#     name  = "region"
#     value = var.region
#   }
#   set {
#     name  = "compartment"
#     value = var.compartment-ocid
#   }
#   set {
#     name  = "ociAuth.authType"
#     value = "instance_principal"
#   }
#   set {
#     name  = "loadBalancer.securityListManagementMode"
#     value = "All"
#   }
#   set {
#     name  = "leaderElection.enabled"
#     value = "true"
#   }
# }