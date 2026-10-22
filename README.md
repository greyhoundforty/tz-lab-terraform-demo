# Power Virtual Server lab

The session clock is [`lab/timeline.html`](lab/timeline.html). The VPC and the Ubuntu server already exist. Guacamole is already running on that server. Terraform reads the VPC and creates the PowerVS resources.

Students open `http://<floating-ip>:8080/guacamole/`, sign in as `student` with password `pvs-lab`, and choose the connection named `Lab server`. The shell is `ubuntu`. Terraform, Ansible, the IBM Cloud CLI, the `power-iaas` plugin, and this repo are already on the server. The repo is cloned at `~/tz-lab-terraform-demo`.

In `nano` or `vi`, click `Ctrl` in the lower right of the Guacamole screen to send a control key. Click it again so it is unselected before Enter, and before the keystrokes that leave the editor. A selected `Ctrl` stays down for the next key.

## What Terraform creates

From `lab/terraform/`, against the existing VPC named in `vpc_name`:

- PowerVS workspace and private network
- PowerVS SSH key, imported from the RSA public key created in the Guacamole shell
- Transit gateway, with connections to that VPC and the workspace
- A delegate route on the VPC for the PowerVS CIDR
- The AIX server, on the second apply, after `aix_image_name` is set

## In the browser session

Create the API key in the portal under Manage → Access (IAM) → API keys, then paste it into the shell. The RSA key below is the PowerVS key. Guacamole already has its own key for this server.

```bash
export IC_API_KEY="<paste the API key>"
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pvs-lab -N ""
ibmcloud login --apikey "$IC_API_KEY" -r us-south
ibmcloud is vpcs
cat ~/.ssh/pvs-lab.pub
```

`ibmcloud is vpcs` is the VPC name for `vpc_name`. The public key is `ssh_public_key`.

```bash
cd ~/tz-lab-terraform-demo/lab/terraform
cp terraform.tfvars.example terraform.tfvars
```

Set `vpc_name` and `ssh_public_key`. Leave `aix_image_name` empty.

```bash
terraform init
terraform plan -out default.tfplan
terraform apply default.tfplan
```

The plan reads the existing VPC and adds the workspace, private network, PowerVS SSH key, transit gateway, both connections, and the VPC route. The AIX server is the second apply.

Copy `workspace_crn` from the output.

```bash
ibmcloud login --apikey "$IC_API_KEY" -r us-south
ibmcloud pi workspace target $(terraform output --raw workspace_crn)
ibmcloud pi image list-catalog
```

Put one AIX image name into `aix_image_name`, then run `terraform plan -out default.tfplan` and `terraform apply default.tfplan` again. That plan adds the image copy and the AIX server on system type `s122`. Apply also installs a route on this server for the PowerVS CIDR through the subnet gateway.

```bash
terraform output -raw aix_ip_address
ping -c 3 "$(terraform output -raw aix_ip_address)"
```

`powervs_cidr` defaults to `192.168.100.0/24`. Change it when that range overlaps a subnet in the existing VPC.

Destroy stays after class: `terraform destroy` in `lab/terraform/`.
