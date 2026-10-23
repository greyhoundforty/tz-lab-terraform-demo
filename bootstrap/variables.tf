variable "ibmcloud_api_key" {
  description = "IBM Cloud API key. Leave null to use the IC_API_KEY environment variable."
  type        = string
  sensitive   = true
  default     = null
}

variable "region" {
  description = "IBM Cloud VPC region of the student servers."
  type        = string
  default     = "us-south"
}

variable "student_instances" {
  description = "Names of the existing Ubuntu virtual servers, one per student. Terraform does not create them."
  type        = list(string)

  validation {
    condition     = length(var.student_instances) > 0 && length(var.student_instances) == length(toset(var.student_instances))
    error_message = "student_instances must list at least one unique virtual server name."
  }
}

variable "ssh_private_key_file" {
  description = "Private key that can SSH to those servers as ubuntu. Used to install the Guacamole password."
  type        = string
}
