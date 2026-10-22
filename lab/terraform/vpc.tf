data "ibm_is_vpc" "existing" {
  name = var.vpc_name
}

locals {
  vpc_zones        = toset([for subnet in data.ibm_is_vpc.existing.subnets : subnet.zone])
  powervs_gateway  = cidrhost(var.powervs_cidr, 1)
  powervs_first_ip = cidrhost(var.powervs_cidr, 2)
  powervs_last_ip  = cidrhost(var.powervs_cidr, -2)
}
