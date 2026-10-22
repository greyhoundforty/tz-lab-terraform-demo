# Power Virtual Server lab

The session clock is [`lab/timeline.html`](lab/timeline.html). Each block lists the commands to run and the result to expect. Students work from the jump host. The instructor applies `bootstrap/` before class. The same page is published at https://images.gh40-dev.systems/timeline.html when that host is updated.

| Minutes | Block | Where the value goes |
| --- | --- | --- |
| 0–10 | CLI: datacenter and a local RSA key | key file on the jump host |
| 10–35 | First Terraform apply | `create_instance = false` |
| 35–40 | CLI: target the workspace, catalog image, SSH key | `aix_image_name`, `ssh_key_name`, `create_instance = true` |
| 40–65 | Second Terraform apply | AIX server |
| 65–75 | Third Terraform apply | `attach_data_volume = true` |
| 75–90 | Ansible from the jump host | playbook uses the AIX private IP |

Destroy stays after class.

## Layout

```text
bootstrap/                         instructor, once, before class
  terraform.tfvars                 gitignored; copy from terraform.tfvars.example
lab/terraform/                     students, three applies, from the jump host
  terraform.tfvars                 gitignored; copy from terraform.tfvars.example
  workspace.tf                     read during the first apply
  gateway.tf                       read during the first apply
  instance.tf                      read during the second apply
lab/ansible/                       students, after the volume is attached
```

`lab/terraform/` is the stack the three applies run. Student edits during class are only the four variables in the table above. Everything else in that tfvars file is copied from `bootstrap` output before class.

## Before class

From `bootstrap/`, with `IC_API_KEY` exported (the IBM provider reads that name):

```bash
cp terraform.tfvars.example terraform.tfvars
# set ssh_public_key to the instructor public key
terraform init
terraform plan
terraform apply
```

Cloud-init on the virtual server installs Terraform, Ansible, the IBM Cloud CLI, and the `power-iaas` plugin (`ibmcloud pi`). It does not write the API key. On the jump host, log the CLI into the student account and export the same key for Terraform:

```bash
export IC_API_KEY="..."
ibmcloud login --apikey "$IC_API_KEY" -r us-south
ibmcloud plugin list    # power-iaas is present
```

Copy these `bootstrap` outputs into `lab/terraform/terraform.tfvars`:

| Bootstrap output | Lab variable |
| --- | --- |
| `resource_group_id` | `resource_group_id` |
| `vpc_id` | `vpc_id` |
| `vpc_crn` | `vpc_crn` |
| `jump_host_private_ip` | `jump_host_private_ip` |
| `subnet_cidr` | leave the PowerVS CIDR on a different range than this value (`10.10.0.0/24` by default) |

`region` stays `us-south`. The PowerVS zone in the lab tfvars is `dal12`, which `ibmcloud pi datacenter list` shows as active.

## 0–10 Catalog

SSH to the jump host with the key from `bootstrap`.

`ibmcloud pi datacenter list` runs with no workspace targeted. Confirm `dal12` is `active`.

```bash
ibmcloud pi datacenter list
ssh-keygen -t rsa -b 4096 -f ~/.ssh/pvs-lab -N ""
```

The PowerVS plugin imports an RSA public key. `ibmcloud pi ssh-key create` takes `--key` as an `ssh-rsa` string.

`ibmcloud pi image list-catalog` reads the catalog of the targeted workspace. Run it in the next CLI block, after the workspace exists. On a fresh jump host, `ibmcloud pi workspace context` prints `CRN is not set` until then.

## 10–35 Workspace and transit gateway

In `lab/terraform/terraform.tfvars`:

```hcl
create_instance    = false
attach_data_volume = false
```

The instance resource stays out of the plan while `create_instance` is false, so this apply does not read `aix_image_name` or `ssh_key_name`. Set those two in the next block.

```bash
cd lab/terraform
terraform init
terraform plan
terraform apply
```

The plan creates the PowerVS workspace, the private subnet, the transit gateway, both connections, and the VPC route. Read `workspace.tf` and `gateway.tf` while the workspace comes up.

Save the workspace CRN from the output. The next CLI command takes that CRN, not the workspace name.

## 35–40 SSH key

```bash
ibmcloud pi workspace target "<workspace_crn>"
ibmcloud pi workspace context
ibmcloud pi image list-catalog
ibmcloud pi ssh-key create pvs-lab --key "$(cat ~/.ssh/pvs-lab.pub)"
```

`image list-catalog` prints the stock images for this workspace. Copy one AIX image name into `aix_image_name`. The name must match the catalog row exactly.

`ssh-key create` stores the key in the targeted workspace (the default visibility). The `KEY_NAME` argument is what Terraform looks up. Put that same name in `ssh_key_name`.

In `lab/terraform/terraform.tfvars`:

```hcl
aix_image_name  = "<name from image list-catalog>"
ssh_key_name    = "pvs-lab"
create_instance = true
```

Leave `attach_data_volume = false`.

## 40–65 AIX server

```bash
terraform plan
terraform apply
```

The plan adds the AIX virtual server and leaves the workspace, subnet, and transit gateway in place. Read `instance.tf` while the server provisions. The output private IP is what Ansible uses.

## 65–75 Data volume

```hcl
attach_data_volume = true
```

```bash
terraform plan
terraform apply
ibmcloud pi volume list
```

The plan adds the volume and the attachment. The AIX server stays in place (no replace). `ibmcloud pi volume list` runs against the workspace targeted in the previous block.

## 75–90 Connectivity

From the jump host, run the playbook in `lab/ansible/` as `root`, with `~/.ssh/pvs-lab`. It retries until port 22 answers, then runs `oslevel -s`, pings `jump_host_private_ip`, and runs `lspv` so the new volume is visible.

## After class

```bash
cd lab/terraform && terraform destroy
cd bootstrap && terraform destroy
```

## This workstation

Checked on 22 Oct 2026 with IBM Cloud CLI 2.48.0 and `power-iaas` 1.11.0, logged into IBM PoC - SFG-DRG-Holdings (`us-south`).

- `ibmcloud pi datacenter list` succeeded. `dal12` is active.
- `ibmcloud pi workspace list` for this account returned no workspaces.
- `ibmcloud pi image list-catalog` with no target returned: a workspace target has not been set.
- The plugin config was pointed at a `dal14` workspace in a different account. With that CRN set, `image list-catalog` returned an account mismatch. `ibmcloud pi workspace context` shows the CRN. That previous target is restored in `~/.bluemix/plugins/power-iaas/config.json`.

The three `terraform plan` / `apply` cycles run from `lab/terraform/`. That directory is not in the repo yet, and `bootstrap/` has no `terraform.tfvars`, so those applies were not run in this check.
