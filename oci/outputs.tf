output "public-instance-ip" {
  value = module.vcn.public-instnace
}

output "private-instance-ip" {
  value = module.vcn.private-instance
}

# data "oci_core_images" "oke-worker-image" {
#   compartment_id            = var.compartment-ocid
#   operating_system          = "Oracle Linux"
#   operating_system_version  = "8"

#   # Filter to only OKE images
#   filter {
#     name   = "display_name"
#     # values = ["Oracle-Linux-8-OKE-${oci_containerengine_cluster.oke_cluster.kubernetes_version}*"]
#     values = ["Oracle-Linux-8.10-2025.05.19-0-OKE-1.31.1*"]
#     regex  = false
#   }
# }

# output "name" {
#   value = oci_core_images.oke-worker-image.images[*].id
# }

data "oci_containerengine_node_pool_option" "oke_images" {
  compartment_id       = var.compartment-ocid
  node_pool_option_id  = "all"
}

output "oke_worker_image_ids" {
  description = "All Oracle Linux 8 OKE image IDs available in this region"
  value = {
    for src in data.oci_containerengine_node_pool_option.oke_images.sources :
    src.source_name => src.image_id
    if length(regexall("Oracle-Linux-8", src.source_name)) > 0
  }
}

output "mysql-admin-password" {
  value = module.rds.mysql-admin-password
  sensitive = true
}

output "mysql-db-ip" {
  value = module.rds.mysql-db-ip
}

output "jenkins-ip" {
  value = module.vcn.jenkins-public-ip
}