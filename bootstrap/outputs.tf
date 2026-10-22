output "resource_group_id" {
  description = "Resource group that holds the jump host. The PowerVS lab stack reuses it."
  value       = module.resource_group.resource_group_id
}

output "vpc_id" {
  description = "VPC ID. The transit gateway connection uses this later."
  value       = module.vpc.vpc_id
}

output "vpc_crn" {
  description = "VPC CRN. The transit gateway connection uses this later."
  value       = module.vpc.vpc_crn
}

output "subnet_cidr" {
  description = "Jump-host subnet CIDR."
  value       = local.jump_host.subnet_cidr
}

output "jump_host_private_ip" {
  description = "Private IP of the jump host. Ansible pings this address from AIX."
  value       = local.jump_host.private_ip
}

output "jump_host_floating_ip" {
  description = "Floating IP students use to SSH to the jump host."
  value       = local.jump_host.floating_ip
}

output "security_group_id" {
  description = "Security group attached to the jump host."
  value       = module.jump_vsi.vsi_security_group.id
}
