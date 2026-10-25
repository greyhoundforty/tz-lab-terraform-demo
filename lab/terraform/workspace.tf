resource "ibm_pi_workspace" "powervs" {
  pi_name              = "${local.name_prefix}-ws"
  pi_datacenter        = var.pi_zone
  pi_resource_group_id = local.resource_group
}

resource "ibm_pi_network" "private" {
  pi_network_name      = "${local.name_prefix}-priv"
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

# pub-vlan draws a public address from IBM. Cloud Shell and student
# workstations can SSH there. They cannot reach the private workspace network.
resource "ibm_pi_network" "public" {
  pi_network_name      = "${local.name_prefix}-pub"
  pi_cloud_instance_id = ibm_pi_workspace.powervs.id
  pi_network_type      = "pub-vlan"
}

resource "ibm_pi_key" "lab" {
  pi_key_name          = "${local.name_prefix}-key"
  pi_ssh_key           = local.ssh_public_key
  pi_cloud_instance_id = ibm_pi_workspace.powervs.id

  lifecycle {
    precondition {
      condition     = startswith(local.ssh_public_key, "ssh-rsa ")
      error_message = "The file at ssh_public_key_file must be an RSA public key, starting with ssh-rsa. PowerVS rejects other key types."
    }
  }
}
