locals {
  create_aix = var.aix_image_name != ""
}

data "ibm_pi_catalog_images" "catalog" {
  count = local.create_aix ? 1 : 0

  pi_cloud_instance_id = ibm_pi_workspace.powervs.id
}

locals {
  aix_catalog_matches = local.create_aix ? [
    for image in data.ibm_pi_catalog_images.catalog[0].images : image
    if image.name == var.aix_image_name
  ] : []
}

resource "ibm_pi_image" "aix" {
  count = local.create_aix ? 1 : 0

  pi_image_id          = local.aix_catalog_matches[0].image_id
  pi_cloud_instance_id = ibm_pi_workspace.powervs.id

  lifecycle {
    precondition {
      condition     = length(local.aix_catalog_matches) == 1
      error_message = "aix_image_name must match exactly one stock image name from ibmcloud pi image list-catalog."
    }
  }
}

resource "ibm_pi_instance" "aix" {
  count = local.create_aix ? 1 : 0

  pi_instance_name     = "${local.name_prefix}-aix"
  pi_memory            = var.pi_memory
  pi_processors        = var.pi_processors
  pi_proc_type         = "shared"
  pi_sys_type          = var.pi_sys_type
  pi_image_id          = ibm_pi_image.aix[0].image_id
  pi_key_pair_name     = ibm_pi_key.lab.pi_key_name
  pi_cloud_instance_id = ibm_pi_workspace.powervs.id
  pi_pin_policy        = "none"
  pi_health_status     = "WARNING"

  pi_network {
    network_id = ibm_pi_network.private.network_id
  }
}

# Runs on the VPC server where Terraform is executed. The delegate route in
# the VPC table only forwards packets that arrive at the subnet gateway.
resource "null_resource" "powervs_route" {
  count = local.create_aix && local.use_vpc ? 1 : 0

  triggers = {
    aix_ip       = ibm_pi_instance.aix[0].pi_network[0].ip_address
    powervs_cidr = var.powervs_cidr
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -eu
      addr=$(ip -4 -o addr show scope global | awk '$2 !~ /^(docker|br-|veth|cni)/ {print $4; exit}')
      gw=$(python3 -c 'import ipaddress,sys; print(next(ipaddress.ip_interface(sys.argv[1]).network.hosts()))' "$addr")
      sudo -n ip route replace ${var.powervs_cidr} via "$gw"
    EOT
  }
}
