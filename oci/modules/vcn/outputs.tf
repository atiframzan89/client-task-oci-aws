output "public-instnace" {
  value = oci_core_instance.public-instance.public_ip
}

output "private-instance" {
  value = oci_core_instance.private-instance.private_ip
}

output "vcn-id" {
  value = oci_core_vcn.customer-vcn.id
}

output "public-subnet-id" {
  value = oci_core_subnet.public-subnet.id
}

output "private-subnet-id" {
  value = oci_core_subnet.private-subnet.id
}

output "jenkins-public-ip" {
  value = oci_core_instance.jenkins-instance.public_ip
}