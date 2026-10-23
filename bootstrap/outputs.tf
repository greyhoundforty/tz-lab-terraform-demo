output "name_prefix" {
  description = "Prefix plus the random suffix used on the VPC resource names."
  value       = local.name_prefix
}

output "vpc_name" {
  description = "VPC created for this lab. Use this as vpc_name in lab/terraform."
  value       = ibm_is_vpc.lab.name
}

output "routing_table_name" {
  description = "Default route table for this VPC. A new suffix creates a new table."
  value       = "${local.name_prefix}-rt"
}

output "instance_name" {
  description = "Ubuntu virtual server that runs Guacamole."
  value       = ibm_is_instance.lab.name
}

output "floating_ip" {
  description = "Public address for Guacamole on port 8080."
  value       = ibm_is_floating_ip.lab.address
}

output "student_access_file" {
  description = "CSV of each student virtual server, its floating IP, and its Guacamole password."
  value       = local_file.student_access.filename
}
