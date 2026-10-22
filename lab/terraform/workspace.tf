resource "ibm_pi_workspace" "powervs" {
  pi_name              = "${var.prefix}-ws"
  pi_datacenter        = var.pi_zone
  pi_resource_group_id = data.ibm_is_vpc.existing.resource_group
}

resource "ibm_pi_network" "private" {
  pi_network_name      = "${var.prefix}-priv"
  pi_cloud_instance_id = ibm_pi_workspace.powervs.id
  pi_network_type      = "vlan"
  pi_cidr              = var.powervs_cidr
  pi_gateway           = local.powervs_gateway
  pi_advertise         = "enable"

  pi_ipaddress_range {
    pi_starting_ip_address = local.powervs_first_ip
    pi_ending_ip_address   = local.powervs_last_ip
  }
}

resource "ibm_pi_key" "lab" {
  pi_key_name          = "${var.prefix}-key"
  pi_ssh_key           = trimspace(var.ssh_public_key)
  pi_cloud_instance_id = ibm_pi_workspace.powervs.id
}
