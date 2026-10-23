data "ibm_resource_group" "lab" {
  is_default = true
}

resource "ibm_is_vpc" "lab" {
  name                      = local.name_prefix
  resource_group            = data.ibm_resource_group.lab.id
  address_prefix_management = "manual"
  # The subnet uses this table. A new suffix means a new VPC and a new table,
  # so a later lab does not add routes to a table a previous run already filled.
  default_routing_table_name  = "${local.name_prefix}-rt"
  default_security_group_name = "${local.name_prefix}-default-sg"
  default_network_acl_name    = "${local.name_prefix}-acl"
}

resource "ibm_is_vpc_address_prefix" "lab" {
  name = "${local.name_prefix}-prefix"
  vpc  = ibm_is_vpc.lab.id
  zone = var.zone
  cidr = var.subnet_cidr
}

resource "ibm_is_public_gateway" "lab" {
  name           = "${local.name_prefix}-gw"
  resource_group = data.ibm_resource_group.lab.id
  vpc            = ibm_is_vpc.lab.id
  zone           = var.zone
}

resource "ibm_is_subnet" "lab" {
  name            = "${local.name_prefix}-subnet"
  resource_group  = data.ibm_resource_group.lab.id
  vpc             = ibm_is_vpc.lab.id
  zone            = var.zone
  ipv4_cidr_block = var.subnet_cidr
  public_gateway  = ibm_is_public_gateway.lab.id

  depends_on = [ibm_is_vpc_address_prefix.lab]
}

resource "ibm_is_security_group" "lab" {
  name           = "${local.name_prefix}-sg"
  resource_group = data.ibm_resource_group.lab.id
  vpc            = ibm_is_vpc.lab.id
}

resource "ibm_is_security_group_rule" "ssh" {
  group     = ibm_is_security_group.lab.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  protocol  = "tcp"
  port_min  = 22
  port_max  = 22
}

resource "ibm_is_security_group_rule" "guacamole" {
  group     = ibm_is_security_group.lab.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  protocol  = "tcp"
  port_min  = 8080
  port_max  = 8080
}

resource "ibm_is_security_group_rule" "egress" {
  group     = ibm_is_security_group.lab.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}
