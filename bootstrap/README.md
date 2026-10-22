# Bootstrap

This directory does not create a VPC. The lab VPC and the Ubuntu server already exist.

`cloud-init.yaml.tftpl` is the image prep that puts Terraform, Ansible, the IBM Cloud CLI, the `power-iaas` plugin, and Docker on that server. It also starts Guacamole on port 8080. Students sign in as `student` with password `pvs-lab` and open the connection named `Lab server`. Students do not apply this directory.

The stack students apply is `lab/terraform/`. It reads the existing VPC and creates the PowerVS workspace, SSH key, transit gateway, and AIX server.
