# Bootstrap

This directory does not create a VPC. The lab VPC and the Ubuntu server already exist.

`cloud-init.yaml.tftpl` is the image prep that puts Terraform, Ansible, the IBM Cloud CLI, the `power-iaas` plugin, and Docker on that server. It also starts Guacamole on port 8080. Students do not apply the image prep.

This directory's Terraform does not create those servers. Copy `terraform.tfvars.example` to `terraform.tfvars`, list the virtual server names in `student_instances`, and set `ssh_private_key_file` to a key that can SSH in as `ubuntu`. With `IC_API_KEY` set, `terraform apply` looks up each server's floating IP, generates a Guacamole password, installs it for the `student` user, and writes `student-access.csv`. Give each student the row for their server. The CSV is gitignored. A new server still boots with password `pvs-lab` until this apply runs.

The stack students apply is `lab/terraform/`. It reads the existing VPC and creates the PowerVS workspace, SSH key, transit gateway, and AIX server.
