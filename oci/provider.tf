terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

provider "oci" {
  region       = var.region
  # tenancy_ocid = var.tenancy_ocid
  config_file_profile = "DEFAULT"
}

data "oci_containerengine_cluster_kube_config" "oke_kubeconfig" {
  cluster_id = module.oke.oke-cluster-id 
  # Use PUBLIC_ENDPOINT or PRIVATE_ENDPOINT depending on your cluster's access setting
  endpoint   = "PRIVATE_ENDPOINT"
   
}

data "oci_containerengine_cluster" "oke_cluster" {
  cluster_id = module.oke.oke-cluster-id
}

# provider "kubernetes" {
#   host                   = module.oke.oke-cluster-endpoint
#   # token                  = data.oci_containerengine_cluster_kube_config.oke_kubeconfig.content
#   # token                  = data.oci_containerengine_cluster_kube_config.oke_kubeconfig
#   token                  = data.oci_containerengine_cluster_kube_config.oke_kubeconfig.content
#   cluster_ca_certificate = base64decode(data.oci_containerengine_cluster_kube_config.oke_kubeconfig.certificate_authority[0].cert_data)
#   # cluster_ca_certificate = base64decode(data.oci_containerengine_cluster_kube_config.oke_kubeconfig.certificate_authority)
#   # cluster_ca_certificate = base64decode(data.oci_containerengine_cluster.oke_cluster.open_id_connect_token_authentication_config.ca_certificate)
  
# }
# provider "helm" {
#   # Helm relies entirely on the configured Kubernetes provider block
#   kubernetes = {
#     host                   = module.oke.oke-cluster-endpoint
#     token                  = data.oci_containerengine_cluster_kube_config.oke_kubeconfig.content
#     # The fix is ensuring the attribute path is correct and fully defined:
#     cluster_ca_certificate = base64decode(data.oci_containerengine_cluster_kube_config.oke_kubeconfig.certificate_authority[0].cert_data)
#   }
#   # kubernetes = {
#   #   host                   = module.oke.oke-cluster-endpoint
#   #   token                  = data.oci_containerengine_cluster_kube_config.oke_kubeconfig.content
#   #   cluster_ca_certificate = base64decode(data.oci_containerengine_cluster_kube_config.oke_kubeconfig.certificate_authority[0].cert_data)
    
#   #   # token                  = data.oci_containerengine_cluster_kube_config.oke_kubeconfig
#   #   # cluster_ca_certificate = base64decode(data.oci_containerengine_cluster.oke_cluster.open_id_connect_token_authentication_config.ca_certificate)
#   # }
# }

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["ce", "cluster", "generate-token", "--cluster-id", local.cluster_id, "--region", local.cluster_region]
    command     = "oci"
  }
}

# https://docs.cloud.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#notes
provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["ce", "cluster", "generate-token", "--cluster-id", local.cluster_id, "--region", local.cluster_region]
      command     = "oci"
    }
  }
}

locals {
  cluster_endpoint       = yamldecode(data.oci_containerengine_cluster_kube_config.oke_kubeconfig.content)["clusters"][0]["cluster"]["server"]
  cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.oke_kubeconfig.content)["clusters"][0]["cluster"]["certificate-authority-data"])
  cluster_id             = yamldecode(data.oci_containerengine_cluster_kube_config.oke_kubeconfig.content)["users"][0]["user"]["exec"]["args"][4]
  cluster_region         = yamldecode(data.oci_containerengine_cluster_kube_config.oke_kubeconfig.content)["users"][0]["user"]["exec"]["args"][6]
}