output "vpc_id" {
  description = "VPC created for the Ubuntu server and the transit gateway."
  value       = ibm_is_vpc.lab.id
}

output "vpc_crn" {
  description = "CRN of the VPC attached to the transit gateway."
  value       = ibm_is_vpc.lab.crn
}

output "workspace_id" {
  description = "PowerVS workspace GUID."
  value       = ibm_pi_workspace.powervs.id
}

output "workspace_crn" {
  description = "PowerVS workspace CRN. Use this with ibmcloud pi workspace target."
  value       = ibm_pi_workspace.powervs.crn
}

output "name_prefix" {
  description = "Prefix used on resource names, for example pvs-07-tf."
  value       = local.name_prefix
}

output "ssh_key_name" {
  description = "PowerVS SSH key imported from the lab public key."
  value       = ibm_pi_key.lab.pi_key_name
}

output "ubuntu_public_ip" {
  description = "Floating IP of the Ubuntu server. SSH here as user ubuntu."
  value       = ibm_is_floating_ip.ubuntu.address
}

output "ubuntu_private_ip" {
  description = "Private IP of the Ubuntu server on the VPC subnet."
  value       = ibm_is_instance.ubuntu.primary_network_interface[0].primary_ip[0].address
}

output "aix_instance_id" {
  description = "AIX virtual server ID, after aix_image_name is set."
  value       = try(ibm_pi_instance.aix[0].id, null)
}

output "aix_ip_address" {
  description = "Private IP of the AIX server. The Ubuntu server pings this address across the transit gateway."
  value       = local.aix_private_ip
}

output "aix_public_ip" {
  description = "Public IP of the AIX server. The lab machine SSHes to this address."
  value       = local.aix_public_ip
}
