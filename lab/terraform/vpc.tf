data "ibm_resource_group" "lab" {
  name = var.resource_group_name
}

locals {
  resource_group       = data.ibm_resource_group.lab.id
  powervs_gateway      = cidrhost(var.powervs_cidr, 1)
  powervs_first_ip     = cidrhost(var.powervs_cidr, 2)
  powervs_last_ip      = cidrhost(var.powervs_cidr, -2)
  ssh_public_key       = trimspace(file(pathexpand(var.ssh_public_key_file)))
  ssh_private_key_file = pathexpand(trimsuffix(var.ssh_public_key_file, ".pub"))
}

data "ibm_is_images" "ubuntu" {
  visibility = "public"
  status     = "available"
}

locals {
  ubuntu_images = [
    for image in data.ibm_is_images.ubuntu.images : image
    if try(image.operating_system[0].name, "") == "ubuntu-24-04-amd64"
  ]
  ubuntu_image_id = try(local.ubuntu_images[0].id, null)
}

resource "ibm_is_vpc" "lab" {
  name           = "${local.name_prefix}-vpc"
  resource_group = local.resource_group
}

resource "ibm_is_subnet" "lab" {
  name                     = "${local.name_prefix}-sn"
  vpc                      = ibm_is_vpc.lab.id
  zone                     = var.vpc_zone
  resource_group           = local.resource_group
  total_ipv4_address_count = 256
}

resource "ibm_is_ssh_key" "lab" {
  name           = "${local.name_prefix}-key"
  public_key     = local.ssh_public_key
  resource_group = local.resource_group
}

# The default group only trusts its own members. SSH comes from the lab
# machine. ICMP comes back from the PowerVS private network.
resource "ibm_is_security_group_rule" "ssh" {
  group     = ibm_is_vpc.lab.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
  protocol  = "tcp"
  port_min  = 22
  port_max  = 22
}

resource "ibm_is_security_group_rule" "icmp" {
  group     = ibm_is_vpc.lab.default_security_group
  direction = "inbound"
  remote    = var.powervs_cidr
  protocol  = "icmp"
}

resource "ibm_is_instance" "ubuntu" {
  name           = "${local.name_prefix}-vsi"
  vpc            = ibm_is_vpc.lab.id
  zone           = var.vpc_zone
  profile        = var.vsi_profile
  image          = local.ubuntu_image_id
  keys           = [ibm_is_ssh_key.lab.id]
  resource_group = local.resource_group

  primary_network_interface {
    subnet          = ibm_is_subnet.lab.id
    security_groups = [ibm_is_vpc.lab.default_security_group]
  }

  depends_on = [
    ibm_is_security_group_rule.ssh,
    ibm_is_security_group_rule.icmp,
  ]

  lifecycle {
    precondition {
      condition     = local.ubuntu_image_id != null
      error_message = "No public Ubuntu 24.04 image (ubuntu-24-04-amd64) was found in this region."
    }
  }
}

resource "ibm_is_floating_ip" "ubuntu" {
  name           = "${local.name_prefix}-fip"
  target         = ibm_is_instance.ubuntu.primary_network_interface[0].id
  resource_group = local.resource_group
}
