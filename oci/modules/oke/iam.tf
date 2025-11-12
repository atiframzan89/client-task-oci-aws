# resource "oci_identity_dynamic_group" "oke_lb_controller_dg" {
#   compartment_id = var.tenancy-ocid
#   name           = "oke-lb-controller-dg"
#   description    = "Dynamic group for OKE Load Balancer Controller"

#   matching_rule = "ALL {resource.type = 'cluster', resource.compartment.id = '${var.compartment-ocid}'}"
# }


# resource "oci_identity_policy" "oke_lb_controller_policy" {
#   compartment_id = var.tenancy-ocid
#   name           = "oke-lb-controller-policy"
#   description    = "Allow OKE LB Controller to manage load balancers"
#   statements = [
#     "Allow dynamic-group oke-lb-controller-dg to manage load-balancers in compartment ${var.compartment-ocid}",
#     "Allow dynamic-group oke-lb-controller-dg to use subnets in compartment ${var.compartment-ocid}",
#     "Allow dynamic-group oke-lb-controller-dg to read instances in compartment ${var.compartment-ocid}"
#   ]
# }