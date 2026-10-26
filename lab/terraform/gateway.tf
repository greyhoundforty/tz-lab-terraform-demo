resource "ibm_tg_gateway" "lab" {
  name           = "${local.name_prefix}-tg"
  location       = var.region
  global         = false
  resource_group = local.resource_group
}

resource "ibm_tg_connection" "vpc" {
  gateway               = ibm_tg_gateway.lab.id
  network_type          = "vpc"
  name                  = "${local.name_prefix}-vpc"
  network_id            = ibm_is_vpc.lab.crn
  default_prefix_filter = "permit"
}

resource "ibm_tg_connection" "powervs" {
  gateway               = ibm_tg_gateway.lab.id
  network_type          = "power_virtual_server"
  name                  = "${local.name_prefix}-powervs"
  network_id            = ibm_pi_workspace.powervs.crn
  default_prefix_filter = "permit"

  depends_on = [ibm_pi_network.private]
}

# Delegate sends matching packets to the transit gateway. For any action
# other than deliver, the provider requires next_hop 0.0.0.0.
resource "ibm_is_vpc_routing_table_route" "powervs" {
  vpc           = ibm_is_vpc.lab.id
  routing_table = ibm_is_vpc.lab.default_routing_table
  zone          = var.vpc_zone
  name          = "${local.name_prefix}-pvs"
  destination   = var.powervs_cidr
  action        = "delegate"
  next_hop      = "0.0.0.0"

  depends_on = [ibm_tg_connection.vpc]
}
