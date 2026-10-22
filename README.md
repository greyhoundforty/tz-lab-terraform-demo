# Power Virtual Server lab

The session clock is [`lab/timeline.html`](lab/timeline.html). The VPC and the Ubuntu server already exist. Terraform does not create them.

Students start in IBM Cloud Shell, then SSH to that server. The server already has Terraform, Ansible, the IBM Cloud CLI, the `power-iaas` plugin, and this repo.

## What Terraform creates

From `lab/terraform/`, against the existing VPC named in `vpc_name`:

- PowerVS workspace and private network
- PowerVS SSH key, imported from the RSA public key created in Cloud Shell
- Transit gateway, with connections to that VPC and the workspace
- A delegate route on the VPC for the PowerVS CIDR
- The AIX server, on the second apply, after `aix_image_name` is set

## Cloud Shell

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pvs-lab -N ""
ibmcloud iam api-key-create pvs-lab -d "PowerVS lab" --file ./pvs-lab-apikey.json
ibmcloud plugin install power-iaas -f
ibmcloud is vpcs
ibmcloud is instances
```

`ibmcloud is vpcs` is the VPC name for `vpc_name`. `ibmcloud is instances` is the Ubuntu server and its floating IP. SSH to that address with the key just created. The server already authorizes that public key.

```bash
ssh -i ~/.ssh/pvs-lab ubuntu@<floating-ip>
```

## On the server

```bash
export IC_API_KEY="$(jq -r .apikey ~/pvs-lab-apikey.json)"
cd lab/terraform
cp terraform.tfvars.example terraform.tfvars
```

Set `vpc_name` and `ssh_public_key` (`cat ~/.ssh/pvs-lab.pub` from Cloud Shell). Leave `aix_image_name` empty.

```bash
terraform init
terraform plan
terraform apply
```

The plan reads the existing VPC and adds the workspace, private network, PowerVS SSH key, transit gateway, both connections, and the VPC route. It does not add a VPC or the AIX server.

Copy `workspace_crn` from the output.

```bash
ibmcloud login --apikey "$IC_API_KEY" -r us-south
ibmcloud pi workspace target "<workspace_crn>"
ibmcloud pi image list-catalog
```

Put one AIX image name into `aix_image_name`, then run `terraform plan` and `terraform apply` again. That plan adds the image copy and the AIX server.

`powervs_cidr` defaults to `192.168.100.0/24`. Change it when that range overlaps a subnet in the existing VPC.

Destroy stays after class: `terraform destroy` in `lab/terraform/`.
