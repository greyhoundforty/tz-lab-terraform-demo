variable "ibmcloud_api_key" {
  description = "IBM Cloud API key used by the provider. Leave null to use the IC_API_KEY environment variable."
  type        = string
  sensitive   = true
  default     = null
}

variable "prefix" {
  description = "Prefix for PowerVS resource names. Keep it short; IBM Cloud name limits apply."
  type        = string
  default     = "pvs-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.prefix))
    error_message = "prefix must start with a letter and contain only lowercase letters, numbers, and hyphens, 2-15 characters."
  }
}

variable "region" {
  description = "IBM Cloud VPC region of the existing VPC. us-south pairs with PowerVS zone dal12."
  type        = string
  default     = "us-south"
}

variable "pi_zone" {
  description = "PowerVS datacenter for the workspace. dal12 is in us-south."
  type        = string
  default     = "dal12"
}

variable "vpc_name" {
  description = "Name of the VPC that already exists. Terraform reads it and does not create a VPC."
  type        = string
}

variable "ssh_public_key" {
  description = "RSA public key generated in Cloud Shell. Terraform imports it into the PowerVS workspace."
  type        = string

  validation {
    condition     = startswith(trimspace(var.ssh_public_key), "ssh-rsa ")
    error_message = "ssh_public_key must be an RSA public key, starting with ssh-rsa."
  }
}

variable "powervs_cidr" {
  description = "Private CIDR created inside the PowerVS workspace. Must not overlap a subnet in the existing VPC."
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
