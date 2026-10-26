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

  # Both networks are attached at create. A network added later is left
  # without an address inside AIX, and pi_network changes are ignored after
  # create, so an existing server is replaced when this public network appears.
  pi_network {
    network_id = ibm_pi_network.public.network_id
  }

  pi_network {
    network_id = ibm_pi_network.private.network_id
  }

  lifecycle {
    replace_triggered_by = [ibm_pi_network.public.id]
  }
}

locals {
  aix_nics = try(ibm_pi_instance.aix[0].pi_network, [])

  aix_private_ip = try([
    for net in local.aix_nics : net.ip_address
    if net.network_id == ibm_pi_network.private.network_id || net.network_name == ibm_pi_network.private.pi_network_name
  ][0], null)

  aix_public_ip = try([
    for net in local.aix_nics : coalesce(net.external_ip != "" ? net.external_ip : null, net.ip_address)
    if net.network_id == ibm_pi_network.public.network_id || net.network_name == ibm_pi_network.public.pi_network_name
  ][0], null)
}

# AIX's default route leaves on the public network. Replies to the VPC would
# follow it and never reach the transit gateway, so each VPC prefix is routed
# through the private network's gateway. The route lasts until AIX reboots.
resource "null_resource" "aix_vpc_route" {
  count = local.create_aix ? 1 : 0

  triggers = {
    aix_public_ip = local.aix_public_ip
    gateway       = local.powervs_gateway
    prefixes      = jsonencode(values(ibm_is_vpc.lab.default_address_prefixes))
  }

  connection {
    type        = "ssh"
    user        = "root"
    host        = local.aix_public_ip
    private_key = file(local.ssh_private_key_file)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      for cidr in values(ibm_is_vpc.lab.default_address_prefixes) :
      "route delete -net ${cidrhost(cidr, 0)} -netmask ${cidrnetmask(cidr)} ${local.powervs_gateway} >/dev/null 2>&1 || true; route add -net ${cidrhost(cidr, 0)} -netmask ${cidrnetmask(cidr)} ${local.powervs_gateway}"
    ]
  }

  depends_on = [ibm_is_vpc_routing_table_route.powervs]
}
