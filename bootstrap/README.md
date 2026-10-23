# Bootstrap

This directory creates the lab VPC and the Ubuntu server. Names end with a random suffix that stays in this Terraform state. A new state gets a new suffix, a new VPC, and a new route table, so a later lab does not add routes to a table a previous run already filled.

`cloud-init.yaml.tftpl` is the image prep passed as the server's user data. It installs Terraform, Ansible, the IBM Cloud CLI, the `power-iaas` plugin, and Docker, and it starts Guacamole on port 8080.

Copy `terraform.tfvars.example` to `terraform.tfvars` and set `ssh_public_key`. With `IC_API_KEY` set:

```bash
terraform init
terraform apply
```

`vpc_name` in the output is the value for `vpc_name` in `lab/terraform/`. Guacamole is at `http://<floating_ip>:8080/guacamole/`.

To set a per-server Guacamole password after cloud-init finishes, set `student_instances` to the instance name and set `ssh_private_key_file`, then apply again. That writes `student-access.csv`. The CSV is gitignored. Until that apply, the server login is `student` / `pvs-lab`.

The stack students apply is `lab/terraform/`. It reads this VPC and creates the PowerVS workspace, SSH key, transit gateway, and AIX server.
