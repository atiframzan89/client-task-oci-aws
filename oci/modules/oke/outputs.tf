output "oke-cluster-endpoint" {
  value = oci_containerengine_cluster.oke_cluster.endpoints[0].public_endpoint
}

output "oke-cluster-id" {
  value = oci_containerengine_cluster.oke_cluster.id
}

# Authority CA
# output "oke_ca_pem" {
#   value = oci_certificates_management_ca.oke-ca.pem_encoded_ca_certificate
# }

# output "oke_ingress_cert_pem" {
#   value = oci_certificates_management_certificate.oke-ingress-cert.certificate_pem
# }

# output "oke_ingress_cert_key_pem" {
#   value     = oci_certificates_management_certificate.oke-ingress-cert.private_key_pem
#   sensitive = true
# }