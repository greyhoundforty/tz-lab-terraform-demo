variable "ibmcloud_api_key" {
  description = "IBM Cloud API key used by the provider. Leave null to use the IC_API_KEY environment variable."
  type        = string
  sensitive   = true
  default     = null
}

variable "prefix" {
  description = "Prefix for resource names in this student account. Keep it short; IBM Cloud name limits apply."
  type        = string
  default     = "pvs-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.prefix))
    error_message = "prefix must start with a letter and contain only lowercase letters, numbers, and hyphens, 2-15 characters."
  }
}

variable "region" {
  description = "IBM Cloud VPC region for the jump host. us-south pairs with the PowerVS zone dal12 used later in the lab."
  type        = string
  default     = "us-south"
}

variable "ssh_public_key" {
  description = "SSH public key installed on the jump host. Students use the matching private key to log in."
  type        = string
}

variable "ssh_source_cidr" {
  description = "CIDR allowed to SSH to the jump host. Narrow this to the instructor or classroom network when you can."
  type        = string
  default     = "0.0.0.0/0"
}

variable "machine_type" {
  description = "VPC virtual server profile. cx2-2x4 is 2 vCPU and 4 GB, enough to run the CLI, Terraform, and Ansible."
  type        = string
  default     = "cx2-2x4"
}

variable "subnet_cidr" {
  description = "CIDR for the single jump-host subnet. Must not overlap the PowerVS subnet created later in the lab."
  type        = string
  default     = "10.10.0.0/24"
}

variable "terraform_version" {
  description = "Terraform version installed on the jump host by cloud-init."
  type        = string
  default     = "1.14.5"
}
