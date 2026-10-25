# Bootstrap

This directory creates the lab VPC and the Ubuntu server. Names end with a random suffix that stays in this Terraform state. A new state gets a new suffix, a new VPC, and a new route table, so a later lab does not add routes to a table a previous run already filled.

`cloud-init.yaml.tftpl` is the image prep passed as the server's user data. It installs Terraform, Ansible, the IBM Cloud CLI, the `power-iaas` plugin, and Docker.

Copy `terraform.tfvars.example` to `terraform.tfvars` and set `ssh_public_key`. With `IC_API_KEY` set:

```bash
terraform init
terraform apply
```

`vpc_name` in the output is the value for `vpc_name` in `lab/terraform/` when a later apply attaches this VPC. Students do not use Guacamole. They run the lab from IBM Cloud Shell or a terminal on their workstation.

The stack students apply is `lab/terraform/`, from Cloud Shell or a workstation terminal. It creates the PowerVS workspace, SSH key, and AIX server. When `vpc_name` is set, it also creates the transit gateway.
