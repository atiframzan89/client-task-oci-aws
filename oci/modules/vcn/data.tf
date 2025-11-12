data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment-ocid
}

# Ubuntu Flavour
data "oci_core_images" "ubuntu" {
  compartment_id          = var.compartment-ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "20.04"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
