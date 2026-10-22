# Bootstrap

This directory does not create a VPC. The lab VPC and the Ubuntu server already exist.

`cloud-init.yaml.tftpl` is the image prep that puts Terraform, Ansible, the IBM Cloud CLI, and the `power-iaas` plugin on that server. Students do not apply it.

The stack students apply is `lab/terraform/`. It reads the existing VPC and creates the PowerVS workspace, SSH key, transit gateway, and AIX server.
