# Power Virtual Server lab

The session clock is [`lab/timelinev2.html`](lab/timelinev2.html). Students work in IBM Cloud Shell, or in the terminal on their workstation. They clone this repo there and apply `lab/terraform/`.

## What Terraform creates

From `lab/terraform/`:

- PowerVS workspace, private network, and public network
- PowerVS SSH key, read from `~/.ssh/pvs-lab.pub`
- When `vpc_name` is set: a transit gateway, connections to that VPC and the workspace, and a delegate route for the PowerVS CIDR
- The AIX server, on the second apply, after `aix_image_name` is set

## In Cloud Shell or a workstation terminal

Create the API key in the portal under Manage → Access (IAM) → API keys, then paste it into the shell. The RSA key below is the PowerVS key.

```bash
export IC_API_KEY="<paste the API key>"
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pvs-lab -N ""
ibmcloud login --apikey "$IC_API_KEY" -r us-south
```

Terraform reads `~/.ssh/pvs-lab.pub`. Leave `vpc_name` unset when this apply is not attaching a VPC.

```bash
cd ~/tz-lab-terraform-demo/lab/terraform
cp terraform.tfvars.example terraform.tfvars
```

Leave `aix_image_name` empty.

```bash
terraform init
terraform plan -out default.tfplan
terraform apply default.tfplan
```

The plan adds the workspace, private network, public network, and PowerVS SSH key. When `vpc_name` is set, it also adds the transit gateway, both connections, and the VPC route. The AIX server is the second apply. It is attached to both networks. An AIX server created before the public network is replaced, because PowerVS only configures the public address when the server is created.

Copy `workspace_crn` from the output.

```bash
ibmcloud login --apikey "$IC_API_KEY" -r us-south
ibmcloud pi workspace target $(terraform output --raw workspace_crn)
ibmcloud pi image list-catalog
```

Put one AIX image name into `aix_image_name`, then run `terraform plan -out default.tfplan` and `terraform apply default.tfplan` again. That plan adds the image copy and the AIX server on system type `s122`. When `vpc_name` is set, apply also installs a route on this server for the PowerVS CIDR through the subnet gateway.

```bash
terraform output -raw aix_public_ip
ping -c 3 "$(terraform output -raw aix_public_ip)"
```

`powervs_cidr` defaults to `192.168.100.0/24`. Change it when that range overlaps a subnet in the existing VPC.

Destroy stays after class: `terraform destroy` in `lab/terraform/`.
