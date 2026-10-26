variable "ibmcloud_api_key" {
  description = "IBM Cloud API key used by the provider. Leave null to use the IC_API_KEY environment variable."
  type        = string
  sensitive   = true
  default     = null
}

variable "prefix" {
  description = "Start of each PowerVS resource name. The lab sets this to the seat prefix plus -tf, for example pvs-07-tf."
  type        = string
  default     = "pvs-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.prefix))
    error_message = "prefix must start with a letter and contain only lowercase letters, numbers, and hyphens, 2-15 characters."
  }
}

variable "region" {
  description = "IBM Cloud region. us-south pairs with PowerVS zone dal12 and VPC zone us-south-1."
  type        = string
  default     = "us-south"
}

variable "pi_zone" {
  description = "PowerVS datacenter for the workspace. dal12 is in us-south."
  type        = string
  default     = "dal12"
}

variable "resource_group_name" {
  description = "Resource group name from ibmcloud resource groups. Lab seats are not given the account Default group, so this must be the group listed for the seat."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "Set resource_group_name to the Name from ibmcloud resource groups. These accounts do not use the Default group."
  }
}

variable "vpc_zone" {
  description = "VPC zone for the Ubuntu server. us-south-1 is in region us-south."
  type        = string
  default     = "us-south-1"
}

variable "vsi_profile" {
  description = "VPC profile for the Ubuntu server. cx2-2x4 is 2 vCPU and 4 GB."
  type        = string
  default     = "cx2-2x4"
}

variable "ssh_public_key_file" {
  description = "Path to the RSA public key generated for PowerVS. Terraform reads this file."
  type        = string
  default     = "~/.ssh/pvs-lab.pub"
}

variable "powervs_cidr" {
  description = "Private CIDR created inside the PowerVS workspace. Must not overlap the VPC address prefixes."
  type        = string
  default     = "192.168.100.0/24"

  validation {
    condition     = can(cidrhost(var.powervs_cidr, 1))
    error_message = "powervs_cidr must be a valid IPv4 CIDR."
  }
}

variable "aix_image_name" {
  description = "Stock AIX image name from ibmcloud pi image list-catalog. Leave empty on the first apply, which creates the workspace before a catalog can be listed."
  type        = string
  default     = ""
}

variable "pi_memory" {
  description = "AIX memory in GiB."
  type        = number
  default     = 4
}

variable "pi_processors" {
  description = "Shared processors visible to AIX."
  type        = number
  default     = 0.25
}

variable "pi_sys_type" {
  description = "PowerVS system type for the AIX server. Power11 uses s122. The Power9 type s922 is deprecated."
  type        = string
  default     = "s122"
}
