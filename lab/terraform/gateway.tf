resource "ibm_tg_gateway" "lab" {
  count = local.use_vpc ? 1 : 0

  name           = "${local.name_prefix}-tg"
  location       = var.region
  global         = false
  resource_group = local.resource_group
}

resource "ibm_tg_connection" "vpc" {
  count = local.use_vpc ? 1 : 0

  gateway               = ibm_tg_gateway.lab[0].id
  network_type          = "vpc"
  name                  = "${local.name_prefix}-vpc"
  network_id            = data.ibm_is_vpc.existing[0].crn
  default_prefix_filter = "permit"
}

resource "ibm_tg_connection" "powervs" {
  count = local.use_vpc ? 1 : 0

  gateway               = ibm_tg_gateway.lab[0].id
  network_type          = "power_virtual_server"
  name                  = "${local.name_prefix}-powervs"
  network_id            = ibm_pi_workspace.powervs.crn
  default_prefix_filter = "permit"
}

# Delegate sends matching packets to the transit gateway. For any action
# other than deliver, the provider requires next_hop 0.0.0.0.
resource "ibm_is_vpc_routing_table_route" "powervs" {
  for_each = local.vpc_zones

  vpc           = data.ibm_is_vpc.existing[0].id
  routing_table = data.ibm_is_vpc.existing[0].default_routing_table
  zone          = each.value
  name          = "${local.name_prefix}-powervs-${each.value}"
  destination   = var.powervs_cidr
  action        = "delegate"
  next_hop      = "0.0.0.0"

  depends_on = [ibm_tg_connection.vpc]
}
