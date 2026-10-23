# Power Virtual Server lab

The session clock is [`lab/timelinev2.html`](lab/timelinev2.html). Before class, apply [`bootstrap/`](bootstrap/README.md). That creates the VPC and the Ubuntu server, and cloud-init on that server installs the lab tools and starts Guacamole. Students then apply `lab/terraform/`, which reads that VPC and creates the PowerVS resources.

Students open `http://<floating-ip>:8080/guacamole/`, sign in as `student` with the password from their lab roster, and choose the connection named `Lab server`. The shell is `ubuntu`. Terraform, Ansible, the IBM Cloud CLI, the `power-iaas` plugin, and this repo are already on the server. The repo is cloned at `~/tz-lab-terraform-demo`.

In `nano` or `vi`, click `Ctrl` in the lower right of the Guacamole screen to send a control key. Click it again so it is unselected before Enter, and before the keystrokes that leave the editor. A selected `Ctrl` stays down for the next key.

## What Terraform creates

From `lab/terraform/`:

- PowerVS workspace and private network
- PowerVS SSH key, read from `~/.ssh/pvs-lab.pub`
- When `vpc_name` is set: a transit gateway, connections to that VPC and the workspace, and a delegate route for the PowerVS CIDR
- The AIX server, on the second apply, after `aix_image_name` is set

## In the browser session

Create the API key in the portal under Manage → Access (IAM) → API keys, then paste it into the shell. The RSA key below is the PowerVS key. Guacamole already has its own key for this server.

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

The plan adds the workspace, private network, and PowerVS SSH key. When `vpc_name` is set, it also adds the transit gateway, both connections, and the VPC route. The AIX server is the second apply.

Copy `workspace_crn` from the output.

```bash
ibmcloud login --apikey "$IC_API_KEY" -r us-south
ibmcloud pi workspace target $(terraform output --raw workspace_crn)
ibmcloud pi image list-catalog
```

Put one AIX image name into `aix_image_name`, then run `terraform plan -out default.tfplan` and `terraform apply default.tfplan` again. That plan adds the image copy and the AIX server on system type `s122`. When `vpc_name` is set, apply also installs a route on this server for the PowerVS CIDR through the subnet gateway.

```bash
terraform output -raw aix_ip_address
ping -c 3 "$(terraform output -raw aix_ip_address)"
```

`powervs_cidr` defaults to `192.168.100.0/24`. Change it when that range overlaps a subnet in the existing VPC.

Destroy stays after class: `terraform destroy` in `lab/terraform/`.
