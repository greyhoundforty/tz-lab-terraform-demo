data "ibm_is_vpc" "existing" {
  count = var.vpc_name != "" ? 1 : 0
  name  = var.vpc_name
}

data "ibm_resource_group" "default" {
  count      = var.vpc_name == "" ? 1 : 0
  is_default = true
}

locals {
  use_vpc          = var.vpc_name != ""
  resource_group   = local.use_vpc ? data.ibm_is_vpc.existing[0].resource_group : data.ibm_resource_group.default[0].id
  vpc_zones        = local.use_vpc ? toset([for subnet in data.ibm_is_vpc.existing[0].subnets : subnet.zone]) : toset([])
  powervs_gateway  = cidrhost(var.powervs_cidr, 1)
  powervs_first_ip = cidrhost(var.powervs_cidr, 2)
  powervs_last_ip  = cidrhost(var.powervs_cidr, -2)
  ssh_public_key   = trimspace(file(pathexpand(var.ssh_public_key_file)))
}
