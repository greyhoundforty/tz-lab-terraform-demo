output "vpc_id" {
  description = "Existing VPC. This stack does not create it."
  value       = try(data.ibm_is_vpc.existing[0].id, null)
}

output "vpc_crn" {
  description = "CRN of the existing VPC attached to the transit gateway."
  value       = try(data.ibm_is_vpc.existing[0].crn, null)
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
  description = "PowerVS SSH key imported from the Cloud Shell public key."
  value       = ibm_pi_key.lab.pi_key_name
}

output "aix_instance_id" {
  description = "AIX virtual server ID, after aix_image_name is set."
  value       = try(ibm_pi_instance.aix[0].id, null)
}

output "aix_ip_address" {
  description = "Private IP of the AIX server on the PowerVS network."
  value       = local.aix_private_ip
}

output "aix_public_ip" {
  description = "Public IP of the AIX server. Cloud Shell and a workstation SSH to this address."
  value       = local.aix_public_ip
}
