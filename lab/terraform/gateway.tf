resource "ibm_tg_gateway" "lab" {
  name           = "${var.prefix}-tg"
  location       = var.region
  global         = false
  resource_group = data.ibm_is_vpc.existing.resource_group
}

resource "ibm_tg_connection" "vpc" {
  gateway               = ibm_tg_gateway.lab.id
  network_type          = "vpc"
  name                  = "${var.prefix}-vpc"
  network_id            = data.ibm_is_vpc.existing.crn
  default_prefix_filter = "permit"
}

resource "ibm_tg_connection" "powervs" {
  gateway               = ibm_tg_gateway.lab.id
  network_type          = "power_virtual_server"
  name                  = "${var.prefix}-powervs"
  network_id            = ibm_pi_workspace.powervs.crn
  default_prefix_filter = "permit"
}

# Delegate sends matching packets to the transit gateway. For any action
# other than deliver, the provider requires next_hop 0.0.0.0.
resource "ibm_is_vpc_routing_table_route" "powervs" {
  for_each = local.vpc_zones

  vpc           = data.ibm_is_vpc.existing.id
  routing_table = data.ibm_is_vpc.existing.default_routing_table
  zone          = each.value
  name          = "${var.prefix}-powervs-${each.value}"
  destination   = var.powervs_cidr
  action        = "delegate"
  next_hop      = "0.0.0.0"

  depends_on = [ibm_tg_connection.vpc]
}
