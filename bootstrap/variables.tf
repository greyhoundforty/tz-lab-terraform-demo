variable "ibmcloud_api_key" {
  description = "IBM Cloud API key. Leave null to use the IC_API_KEY environment variable."
  type        = string
  sensitive   = true
  default     = null
}

variable "region" {
  description = "IBM Cloud VPC region. us-south pairs with PowerVS zone dal12."
  type        = string
  default     = "us-south"
}

variable "zone" {
  description = "VPC zone for the Ubuntu server. us-south-1 is in us-south."
  type        = string
  default     = "us-south-1"
}

variable "prefix" {
  description = "Start of each VPC resource name. Terraform appends a stable random suffix so a later lab gets its own VPC and route table."
  type        = string
  default     = "pvs-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}$", var.prefix))
    error_message = "prefix must start with a letter and contain only lowercase letters, numbers, and hyphens, 2-15 characters."
  }
}

variable "subnet_cidr" {
  description = "IPv4 CIDR for the lab subnet. Must not overlap the PowerVS CIDR."
  type        = string
  default     = "10.240.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 1))
    error_message = "subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "instance_profile" {
  description = "VPC instance profile for the Ubuntu server."
  type        = string
  default     = "bx2-2x8"
}

variable "ssh_public_key" {
  description = "Public key installed on the Ubuntu server for the ubuntu user."
  type        = string

  validation {
    condition     = startswith(trimspace(var.ssh_public_key), "ssh-")
    error_message = "ssh_public_key must be an SSH public key."
  }
}

variable "student_instances" {
  description = "Optional names of Ubuntu servers that should receive a Guacamole password. Leave empty when this apply is only creating the VPC and server."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.student_instances) == length(toset(var.student_instances))
    error_message = "student_instances names must be unique."
  }
}

variable "ssh_private_key_file" {
  description = "Private key that can SSH to student_instances as ubuntu. Required only when that list is not empty."
  type        = string
  default     = null
}
