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
  vcn_id           = var.vcn-id 
  kubernetes_version = "v1.31.1"
  # Only on enhanced cluster we can install the loadbalancer controller using addon          
  type            = "ENHANCED_CLUSTER"
  
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

# OKE Ingress Addon
data "oci_containerengine_addon_options" "oci-lb-controller-options" {
  addon_name                          = "NativeIngressController"
  kubernetes_version                  = oci_containerengine_cluster.oke_cluster.kubernetes_version
}

data "oci_containerengine_addon_options" "oci-cert-manager-options" {
  addon_name                          = "CertManager"
  kubernetes_version                  = oci_containerengine_cluster.oke_cluster.kubernetes_version
}


resource "oci_containerengine_addon" "oci-native-ingress-lb" {
    addon_name                        = data.oci_containerengine_addon_options.oci-lb-controller-options.addon_name
    cluster_id                        = oci_containerengine_cluster.oke_cluster.id
    remove_addon_resources_on_delete  = true
    depends_on = [ oci_containerengine_addon.oci-cert-manager ]
    configurations {
      key = "compartmentId"
      value = var.compartment-ocid
    }
    configurations {
      key = "loadBalancerSubnetId"
      value = var.public-subnet-id
    }
  #   configurations {
  #   key   = "oci-native-ingress-controller-config"
    
  #   # Pass the required IDs as a JSON string.
  #   # We use your existing variables.
  #   value = jsonencode({
  #     compartmentId      = "${var.compartment-ocid}"
  #     loadBalancerSubnetId = "${var.public-subnet-id}" # Use your public LB subnet
  #   })
  # }
}

resource "oci_containerengine_addon" "oci-cert-manager" {
    addon_name                        = data.oci_containerengine_addon_options.oci-cert-manager-options.addon_name
    cluster_id                        = oci_containerengine_cluster.oke_cluster.id
    remove_addon_resources_on_delete  = true
    
}


# IAM Policy and Dynamic Grouping
data "oci_identity_compartment" "oke_compartment" {
  id = var.compartment-ocid
}

# ---------------------------------------------------------------------------
# Dynamic Group
# ---------------------------------------------------------------------------

# resource "oci_identity_dynamic_group" "oke-worker-nodes-dg" {
#   compartment_id = var.tenancy-ocid
  
#   name           = "${var.customer}-oke-worker-nodes-dg-${var.environment}"
#   description    = "Dynamic Group for all OKE worker nodes in the cluster compartment."
  
#   # matching_rule = "ALL {instance.compartment.id = '${var.compartment-ocid}'}"
#   matching_rule = "ALL {resource.type = 'cluster', resource.id = '${oci_containerengine_cluster.oke_cluster.id}'}"
# }

# # ---------------------------------------------------------------------------
# # IAM Policy
# # ---------------------------------------------------------------------------

# # **CORRECTED RESOURCE TYPE**
# resource "oci_identity_policy" "oke-lb-controller-policy" {
#   depends_on = [ oci_identity_dynamic_group.oke-worker-nodes-dg ]
#   compartment_id = var.tenancy-ocid
  
#   name           = "${var.customer}-oke-lb-controller-policy-${var.environment}"
#   description    = "Grants OKE worker nodes permissions for the OCI LB Controller."

#   statements = [
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to manage load-balancers in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to manage network-load-balancers in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to manage network-security-groups in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to manage security-lists in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to use subnets in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to use vnics in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to use private-ips in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to manage public-ips in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to inspect vcns in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to manage certificates-family in compartment ${data.oci_identity_compartment.oke_compartment.name}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke-worker-nodes-dg.name} to manage ca-bundles in compartment ${data.oci_identity_compartment.oke_compartment.name}"
#   ]
# }

# resource "oci_identity_policy" "oke_lb_addon_policy" {
#   # This policy must be in the ROOT compartment (tenancy)
#   compartment_id = var.tenancy-ocid
  
#   name           = "${var.customer}-oke-lb-addon-policy-${var.environment}"
#   description    = "Grants OKE cluster permissions for OCI addons"
  
#   statements = [
#     # --- ADD THIS LINE ---
#     # This allows the controller to read its own cluster's details
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_dg.name} to read clusters in compartment id ${var.compartment-ocid}",
#     # ---------------------

#     # Policies for the Load Balancer
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_dg.name} to manage load-balancers in compartment id ${var.compartment-ocid}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_dg.name} to manage network-load-balancers in compartment id ${var.compartment-ocid}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_dg.name} to use subnets in compartment id ${var.compartment-ocid}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_dg.name} to use vnics in compartment id ${var.compartment-ocid}",
#     "Allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_dg.name} to inspect compartments in tenancy"
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